package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/h2non/filetype"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/spaces"
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

func setSpeakerPrivateImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	// 10 KB
	var maxSize int64 = 10 << 10

	if err := r.ParseMultipartForm(maxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", maxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > maxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", maxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event", http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file", http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type", http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadSpeakerInternalImage(currentEvent.ID, speakerID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerInternalImage(speakerID, *url)
	if err != nil {
		http.Error(w, "Couldn't update speaker internal image", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func setSpeakerPublicImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	// 10 KB
	var maxSize int64 = 10 << 10

	if err := r.ParseMultipartForm(maxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", maxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > maxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", maxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event", http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file", http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type", http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadSpeakerPublicImage(currentEvent.ID, speakerID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerPublicImage(speakerID, *url)
	if err != nil {
		http.Error(w, "Couldn't update speaker internal image", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func setSpeakerCompanyImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	// 10 KB
	var maxSize int64 = 10 << 10

	if err := r.ParseMultipartForm(maxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", maxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > maxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", maxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event", http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file", http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type", http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadSpeakerCompanyImage(currentEvent.ID, speakerID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerCompanyImage(speakerID, *url)
	if err != nil {
		http.Error(w, "Couldn't update speaker internal image", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func addSpeakerFlightInfo(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	var cfid = &mongodb.CreateFlightInfoData{}

	if err := cfid.ParseBody(r.Body); err != nil {
		http.Error(w, fmt.Sprintf("Could not parse body: %s", err.Error()), http.StatusBadRequest)
		return
	}

	newFlightInfo, err := mongodb.FlightInfo.CreateFlightInfo(*cfid)

	if err != nil {
		http.Error(w, "Could not create flight info", http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.AddSpeakerFlightInfo(speakerID, newFlightInfo.ID)

	if err != nil {
		http.Error(w, "Could not add flight info to speaker", http.StatusExpectationFailed)

		// delete created flight info
		if _, err := mongodb.FlightInfo.DeleteFlightInfo(newFlightInfo.ID); err != nil {
			log.Printf("error deleting flight info: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func deleteSpeakerFlightInfo(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])
	flightInfoID, _ := primitive.ObjectIDFromHex(params["flightInfoID"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID", http.StatusNotFound)
		return
	}

	backupFlightInfo, _ := mongodb.FlightInfo.GetFlightInfo(flightInfoID)

	updatedSpeaker, err := mongodb.Speakers.RemoveSpeakerFlightInfo(speakerID, flightInfoID)
	if err != nil {
		http.Error(w, "Could not remove flight info from speaker", http.StatusExpectationFailed)
		return
	}

	_, err = mongodb.FlightInfo.DeleteFlightInfo(flightInfoID)
	if err != nil {
		http.Error(w, "Could not delete flight info", http.StatusExpectationFailed)

		if backupFlightInfo == nil {
			log.Printf("no backup flight info to compensate the failed deletion of the flight info: %s\n", err.Error())
		}

		// create deleted flight info
		if _, err := mongodb.Speakers.AddSpeakerFlightInfo(speakerID, flightInfoID); err != nil {
			log.Printf("error adding flight info to speaker: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}
