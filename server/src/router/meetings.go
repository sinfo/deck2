package router

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)

func getMeeting(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	meeting, err := mongodb.Meetings.GetMeeting(id)
	if err != nil {
		http.Error(w, "Could not find meeting", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(meeting)
}

func deleteMeeting(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	meeting, err := mongodb.Meetings.DeleteMeeting(id)
	if err != nil {
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(meeting)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindDeleted,
			Meeting: &meeting.ID,
		})
	}
}

func createMeeting(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var cmd = mongodb.CreateMeetingData{}

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	meeting, err := mongodb.Meetings.CreateMeeting(cmd)
	if err != nil {
		http.Error(w, "Could not create team", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(meeting)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreated,
			Meeting: &meeting.ID,
		})
	}
}

func getMeetings(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetMeetingsOptions{}

	team := urlQuery.Get("team")
	var teamID primitive.ObjectID
	company := urlQuery.Get("company")
	var companyID primitive.ObjectID
	event := urlQuery.Get("event")
	var eventID int
	var err error

	if len(team) > 0 {
		teamID, err = primitive.ObjectIDFromHex(team)
		if err != nil {
			http.Error(w, "Error parsing query", http.StatusBadRequest)
			return
		}
		options.Team = &teamID
	}

	if len(company) > 0 {
		companyID, err = primitive.ObjectIDFromHex(company)
		if err != nil {
			http.Error(w, "Error parsing query", http.StatusBadRequest)
			return
		}
		options.Company = &companyID
	}

	if len(event) > 0 {
		eventID, err = strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Error parsing query", http.StatusBadRequest)
			return
		}
		options.Event = &eventID
	}

	meetings, err := mongodb.Meetings.GetMeetings(options)
	if err != nil {
		http.Error(w, "Event, company or team not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(meetings)
}
