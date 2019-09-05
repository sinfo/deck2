package router

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getSession(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	sessionID, _ := primitive.ObjectIDFromHex(params["id"])

	session, err := mongodb.Sessions.GetSession(sessionID)

	if err != nil {
		http.Error(w, "Could not find session", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(session)
}

func getSessions(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetSessionsOptions{}

	event := urlQuery.Get("event")
	before := urlQuery.Get("before")
	after := urlQuery.Get("after")
	space := urlQuery.Get("space")
	kind := urlQuery.Get("kind")
	company := urlQuery.Get("company")
	speaker := urlQuery.Get("speaker")

	if len(event) > 0 {
		eventValue, err := strconv.Atoi(event)

		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		if _, err := mongodb.Events.GetEvent(eventValue); err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.Event = &eventValue

	}

	if len(before) > 0 {
		beforeDate, err := time.Parse(time.RFC3339, before)

		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.Before = &beforeDate
	}

	if len(after) > 0 {
		afterDate, err := time.Parse(time.RFC3339, after)

		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.After = &afterDate
	}

	if len(space) > 0 {
		options.Space = &space
	}

	if len(kind) > 0 {
		kindValue := new(models.SessionKind)

		err := kindValue.Parse(kind)
		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.Kind = kindValue
	}

	if len(company) > 0 {
		companyValue, err := primitive.ObjectIDFromHex(company)

		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.Company = &companyValue
	}

	if len(speaker) > 0 {
		speakerValue, err := primitive.ObjectIDFromHex(speaker)

		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.Speaker = &speakerValue
	}

	sessions, err := mongodb.Sessions.GetSessions(options)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(sessions)
}

func getPublicSessions(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetSessionsPublicOptions{}

	event := urlQuery.Get("event")
	kind := urlQuery.Get("kind")

	if len(event) > 0 {
		eventValue, err := strconv.Atoi(event)

		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		if _, err := mongodb.Events.GetEvent(eventValue); err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.EventID = &eventValue

	}

	if len(kind) > 0 {
		kindValue := new(models.SessionKind)

		err := kindValue.Parse(kind)
		if err != nil {
			json.NewEncoder(w).Encode(make([]*models.Session, 0))
			return
		}

		options.Kind = kindValue
	}

	sessions, err := mongodb.Sessions.GetPublicSessions(options)

	if err != nil {
		json.NewEncoder(w).Encode(make([]*models.Session, 0))
		return
	}

	json.NewEncoder(w).Encode(sessions)
}

func updateSession(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	sessionID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Sessions.GetSession(sessionID); err != nil {
		http.Error(w, "Could not find session", http.StatusNotFound)
		return
	}

	var usd = &mongodb.UpdateSessionData{}

	if err := usd.ParseBody(r.Body); err != nil {
		http.Error(w, fmt.Sprintf("Could not parse body: %v", err.Error()), http.StatusBadRequest)
		return
	}

	updatedSession, err := mongodb.Sessions.UpdateSession(sessionID, *usd)

	if err != nil {
		http.Error(w, "Could not create session", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSession)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdated,
			Session: &updatedSession.ID,
		})
	}
}
