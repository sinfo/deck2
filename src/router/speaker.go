package router

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getSpeaker(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	speaker, err := mongodb.Speakers.GetSpeaker(speakerID)

	if err != nil {
		http.Error(w, "Unable to get speaker", http.StatusNotFound)
	}

	json.NewEncoder(w).Encode(speaker)
}

func getSpeakers(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetSpeakersOptions{}

	event := urlQuery.Get("event")
	member := urlQuery.Get("member")
	name := urlQuery.Get("name")

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format", http.StatusBadRequest)
			return
		}
		options.EventID = &eventID
	}

	if len(member) > 0 {
		memberID, err := primitive.ObjectIDFromHex(member)
		if err != nil {
			http.Error(w, "Invalid member ID format", http.StatusBadRequest)
			return
		}
		options.MemberID = &memberID
	}

	if len(name) > 0 {
		options.Name = &name
	}

	speakers, err := mongodb.Speakers.GetSpeakers(options)

	if err != nil {
		http.Error(w, "Unable to get speakers", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(speakers)
}

func createSpeaker(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var cpd = &mongodb.CreateSpeakerData{}

	if err := cpd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(*cpd)

	if err != nil {
		http.Error(w, "Could not create speaker", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newSpeaker)
}

func updateSpeaker(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	var usd = &mongodb.UpdateSpeakerData{}

	if err := usd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeaker(speakerID, *usd)

	if err != nil {
		http.Error(w, "Could not update company data", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func addSpeakerParticipation(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(speakerID, credentials.ID)

	if err != nil {
		http.Error(w, "Could not add participation to speaker", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func updateSpeakerParticipation(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	var uspd = &mongodb.UpdateSpeakerParticipationData{}

	if err := uspd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerParticipation(speakerID, *uspd)

	if err != nil {
		http.Error(w, "Could not update speaker data", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func stepSpeakerStatus(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])
	step, err := strconv.Atoi(params["step"])

	if err != nil {
		http.Error(w, "Invalid step", http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.StepStatus(speakerID, step)

	if err != nil {
		http.Error(w, "Could not update speaker status", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func getSpeakerValidSteps(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	validSteps := validStepsResponse{}

	steps, err := mongodb.Speakers.GetSpeakerParticipationStatusValidSteps(speakerID)

	if err != nil {
		http.Error(w, "Speaker without participation on the current event", http.StatusBadRequest)
		return
	}

	if steps != nil {
		validSteps.Steps = *steps
	}

	json.NewEncoder(w).Encode(validSteps)
}

func setSpeakerStatus(w http.ResponseWriter, r *http.Request) {

	status := new(models.ParticipationStatus)

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])
	err := status.Parse(params["status"])

	if err != nil {
		http.Error(w, "Invalid status", http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerParticipationStatus(speakerID, *status)

	if err != nil {
		http.Error(w, "Could not update speaker status", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}
