package router

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"golang.org/x/oauth2"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/option"

	"github.com/gorilla/mux"
)

func getTeams(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetTeamsOptions{}

	name := urlQuery.Get("name")
	member := urlQuery.Get("member")
	event := urlQuery.Get("event")

	if len(name) > 0 {
		options.Name = &name
	}

	if len(member) > 0 {
		memberID, err := primitive.ObjectIDFromHex(member)
		if err != nil {
			http.Error(w, "Invalid member ID format", http.StatusBadRequest)
			return
		}
		options.Member = &memberID
	}

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format", http.StatusBadRequest)
			return
		}
		options.Event = &eventID
	}

	teams, err := mongodb.Teams.GetTeams(options)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(teams)
}

func createTeam(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ctd = &mongodb.CreateTeamData{}

	if err := ctd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newTeam, err := mongodb.Teams.CreateTeam(*ctd)

	if err != nil {
		http.Error(w, "Could not create team", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newTeam)
}

func getTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	team, err := mongodb.Teams.GetTeam(id)

	if err != nil {
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func deleteTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	team, err := mongodb.Teams.DeleteTeam(id)

	if err != nil {
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func updateTeam(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ctd = &mongodb.CreateTeamData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := ctd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedTeam, err := mongodb.Teams.UpdateTeam(id, *ctd)

	if err != nil {
		http.Error(w, "Could not update team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedTeam)
}

func addTeamMember(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var utmd = &mongodb.UpdateTeamMemberData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := utmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	team, err := mongodb.Teams.AddTeamMember(id, *utmd)
	if err != nil {
		if err.Error() == "Duplicate member" {
			http.Error(w, err.Error(), http.StatusBadRequest)
		} else {
			http.Error(w, "Team or member not found", http.StatusNotFound)
		}
		return
	}

	json.NewEncoder(w).Encode(team)
}

func updateTeamMemberRole(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var utmd = &mongodb.UpdateTeamMemberData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := utmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	team, err := mongodb.Teams.UpdateTeamMemberRole(id, *utmd)
	if err != nil {
		http.Error(w, "Team or member not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func deleteTeamMember(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])
	memberID, _ := primitive.ObjectIDFromHex(params["memberID"])

	team, err := mongodb.Teams.DeleteTeamMember(id, memberID)
	if err != nil {
		http.Error(w, "Team or member not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func addTeamMeeting(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	var cmd mongodb.CreateMeetingData

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	meeting, err := mongodb.Meetings.CreateMeeting(cmd)
	if err != nil {
		http.Error(w, "Could not create team", http.StatusExpectationFailed)
		return
	}

	team, err := mongodb.Teams.AddMeeting(id, meeting.ID)
	if err != nil {
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {

		ctx := context.Background()

		token, err := mongodb.Tokens.GetToken(credentials.Token)
		if err != nil {
			http.Error(w, "Could not find token in database", http.StatusNotFound)
			return
		}

		newToken := new(oauth2.Token)
		newToken.Expiry = token.Expiry
		newToken.RefreshToken = token.Refresh
		newToken.AccessToken = token.Access

		client := auth.OauthConfig.Client(ctx, newToken)

		calendarService, err := calendar.NewService(ctx, option.WithHTTPClient(client))
		if err != nil {
			http.Error(w, "Could not start calendar: "+err.Error(), http.StatusExpectationFailed)
			return
		}

		calendarList, err := calendarService.CalendarList.List().Do()
		if err != nil {
			http.Error(w, "Could not list calendars"+err.Error(), http.StatusExpectationFailed)
			return
		}

		var calendarID string

		for _, s := range calendarList.Items {
			if s.Summary == "SINFO General Calendar" {
				calendarID = s.Id
			}
		}

		newEvent := &calendar.Event{
			AnyoneCanAddSelf: true,
			Id:               meeting.ID.Hex(),
			Location:         meeting.Place,
			Summary:          team.Name + " meeting",
			Start:            &calendar.EventDateTime{DateTime: meeting.Begin.Format(time.RFC3339)},
			End:              &calendar.EventDateTime{DateTime: meeting.End.Format(time.RFC3339)},
		}

		createdEvent, err := calendarService.Events.Insert(calendarID, newEvent).Do()
		if err != nil {
			http.Error(w, "Could not add event to calendar", http.StatusExpectationFailed)
			return
		}

		log.Printf("Created meeting %s starting at %s", createdEvent.Summary, createdEvent.Start)
	}

	json.NewEncoder(w).Encode(team)
}

func deleteTeamMeeting(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	teamID, _ := primitive.ObjectIDFromHex(params["id"])
	meetingID, _ := primitive.ObjectIDFromHex(params["meetingID"])

	meeting, err := mongodb.Teams.DeleteTeamMeeting(teamID, meetingID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {

		ctx := context.Background()

		token, err := mongodb.Tokens.GetToken(credentials.Token)
		if err != nil {
			http.Error(w, "Could not find token in database", http.StatusNotFound)
			return
		}

		newToken := new(oauth2.Token)
		newToken.Expiry = token.Expiry
		newToken.RefreshToken = token.Refresh
		newToken.AccessToken = token.Access

		client := auth.OauthConfig.Client(ctx, newToken)

		calendarService, err := calendar.NewService(ctx, option.WithHTTPClient(client))
		if err != nil {
			http.Error(w, "Could not start calendar: "+err.Error(), http.StatusExpectationFailed)
			return
		}

		calendarList, err := calendarService.CalendarList.List().Do()
		if err != nil {
			http.Error(w, "Could not list calendars"+err.Error(), http.StatusExpectationFailed)
			return
		}

		var calendarID string

		for _, s := range calendarList.Items {
			if s.Summary == "SINFO General Calendar" {
				calendarID = s.Id
			}
		}

		deletedEvent, err := calendarService.Events.Get(calendarID, meetingID.Hex()).Do()
		if err != nil {
			http.Error(w, "Could not find meeting in calendar", http.StatusExpectationFailed)
			return
		}

		err = calendarService.Events.Delete(calendarID, meetingID.Hex()).Do()
		if err != nil {
			http.Error(w, "Could not delete event from calendar", http.StatusExpectationFailed)
			return
		}

		log.Printf("Deleted event %s", deletedEvent.Summary)
	}

	json.NewEncoder(w).Encode(meeting)

}
