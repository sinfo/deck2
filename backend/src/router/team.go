package router

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)

func getTeams(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetTeamsOptions{}

	name := urlQuery.Get("name")
	member := urlQuery.Get("member")
	memberName := urlQuery.Get("memberName")
	event := urlQuery.Get("event")

	if len(name) > 0 {
		options.Name = &name
	}

	if len(member) > 0 {
		memberID, err := primitive.ObjectIDFromHex(member)
		if err != nil {
			http.Error(w, "Invalid member ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.Member = &memberID
	}

	if len(memberName) > 0 {
		options.MemberName = &memberName
	}

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.Event = &eventID
	}

	teams, err := mongodb.Teams.GetTeams(options)

	if err != nil {
		http.Error(w, "Unable to make query do database: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(teams)
}

func createTeam(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ctd = &mongodb.CreateTeamData{}

	if err := ctd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newTeam, err := mongodb.Teams.CreateTeam(*ctd)

	if err != nil {
		http.Error(w, "Could not create team: " + err.Error(), http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newTeam)
}

func getTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	team, err := mongodb.Teams.GetTeam(id)

	if err != nil {
		http.Error(w, "Could not find team: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func deleteTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	team, err := mongodb.Teams.DeleteTeam(id)

	if err != nil {
		http.Error(w, "Could not find team: " + err.Error(), http.StatusNotFound)
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
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedTeam, err := mongodb.Teams.UpdateTeam(id, *ctd)

	if err != nil {
		http.Error(w, "Could not update team: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedTeam)
}

func addTeamMember(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var ctmd = &mongodb.CreateTeamMemberData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := ctmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	team, err := mongodb.Teams.AddTeamMember(id, *ctmd)
	if err != nil {
		if err.Error() == "Duplicate member" {
			http.Error(w, err.Error(), http.StatusBadRequest)
		} else {
			http.Error(w, "Team or member not found: " + err.Error(), http.StatusNotFound)
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
	memberID, _ := primitive.ObjectIDFromHex(params["memberID"])

	if err := utmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	team, err := mongodb.Teams.UpdateTeamMemberRole(id, memberID, *utmd)
	if err != nil {
		http.Error(w, "Team or member not found: " + err.Error(), http.StatusNotFound)
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
		http.Error(w, "Team or member not found: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func addTeamMeeting(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	var cmd mongodb.CreateMeetingData

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	meeting, err := mongodb.Meetings.CreateMeeting(cmd)
	if err != nil {
		http.Error(w, "Could not create team: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	team, err := mongodb.Teams.AddMeeting(id, meeting.ID)
	if err != nil {
		http.Error(w, "Could not find team: " + err.Error(), http.StatusNotFound)
		return
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

	json.NewEncoder(w).Encode(meeting)

}
