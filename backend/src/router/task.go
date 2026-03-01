package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================
// Company Tasks
// ============================================================

func updateCompanyTasks(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: "+err.Error(), http.StatusNotFound)
		return
	}

	var data = &mongodb.UpdateCompanyTasksData{}

	if err := data.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdateCompanyTasks(companyID, *data)

	if err != nil {
		http.Error(w, "Could not update company tasks: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdated,
			Company: &updatedCompany.ID,
		})
	}
}

// ============================================================
// Speaker Tasks
// ============================================================

func updateSpeakerTasks(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: "+err.Error(), http.StatusNotFound)
		return
	}

	var data = &mongodb.UpdateSpeakerTasksData{}

	if err := data.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerTasks(speakerID, *data)

	if err != nil {
		http.Error(w, "Could not update speaker tasks: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdated,
			Speaker: &updatedSpeaker.ID,
		})
	}
}
