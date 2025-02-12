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
	"github.com/sinfo/deck2/src/config"
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
		http.Error(w, "Unable to get speaker: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(speaker)
}

func deleteSpeaker(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	deletedSpeaker, err := mongodb.Speakers.DeleteSpeaker(speakerID)
	if err != nil {
		http.Error(w, "Error deleting speaker: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(deletedSpeaker)
}

func getSpeakerPublic(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	speaker, err := mongodb.Speakers.GetSpeakerPublic(speakerID)

	if err != nil {
		http.Error(w, "Unable to get speaker: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(speaker)
}

func getSpeakers(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetSpeakersOptions{}

	event := urlQuery.Get("event")
	member := urlQuery.Get("member")
	name := urlQuery.Get("name")
	numRequests := urlQuery.Get("numRequests")
	maxSpeaksInRequest := urlQuery.Get("maxSpeaksInRequest")
	sortMethod := urlQuery.Get("sortMethod")

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.EventID = &eventID
	}

	if len(member) > 0 {
		memberID, err := primitive.ObjectIDFromHex(member)
		if err != nil {
			http.Error(w, "Invalid member ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.MemberID = &memberID
	}

	if len(name) > 0 {
		options.Name = &name
	}

	if len(numRequests) > 0 {
		numReq, err := strconv.ParseInt(numRequests, 10, 64)
		if err != nil {
			http.Error(w, "Number of Requests: Invalid Speaker ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.NumRequests = &numReq
	}

	if len(maxSpeaksInRequest) > 0 {
		maxSpeaks, err := strconv.ParseInt(maxSpeaksInRequest, 10, 64)
		if err != nil {
			http.Error(w, "Max Speakers in Request: Invalid number format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.MaxSpeaksInRequest = &maxSpeaks
	}

	if len(sortMethod) > 0 {
		options.SortingMethod = &sortMethod
	}

	speakers, err := mongodb.Speakers.GetSpeakers(options)

	if err != nil {
		http.Error(w, "Unable to get speakers: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(speakers)
}

func getSpeakersPublic(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetSpeakersPublicOptions{}

	name := urlQuery.Get("name")
	event := urlQuery.Get("event")

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.EventID = &eventID
	}

	if len(name) > 0 {
		options.Name = &name
	}

	publicSpeakers, err := mongodb.Speakers.GetPublicSpeakers(options)

	if err != nil {
		http.Error(w, "Unable to make query do database: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(publicSpeakers)
}

func createSpeaker(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var cpd = &mongodb.CreateSpeakerData{}

	if err := cpd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(*cpd)

	if err != nil {
		http.Error(w, "Could not create speaker: " + err.Error(), http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreated,
			Speaker: &newSpeaker.ID,
		})
	}
}

func updateSpeaker(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var usd = &mongodb.UpdateSpeakerData{}

	if err := usd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeaker(speakerID, *usd)

	if err != nil {
		http.Error(w, "Could not update speaker data: " + err.Error(), http.StatusExpectationFailed)
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
		http.Error(w, "Could not add participation to speaker: " + err.Error(), http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
		Kind:    models.NotificationKindUpdatedParticipation,
		Speaker: &updatedSpeaker.ID,
	})
}

func updateSpeakerParticipation(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var uspd = &mongodb.UpdateSpeakerParticipationData{}

	if err := uspd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerParticipation(speakerID, *uspd)

	if err != nil {
		http.Error(w, "Could not update speaker data: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipation,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func deleteSpeakerThread(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])
	threadID, _ := primitive.ObjectIDFromHex(params["threadID"])

	_, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}
	
	speaker, err := mongodb.Speakers.DeleteSpeakerThread(id, threadID)
	if err != nil {
		http.Error(w, "Speaker or thread not found: " + err.Error(), http.StatusNotFound)
		return
	}
	
	// Delete thread and posts (comments) associated to it - only if 
	// thread was deleted sucessfully from speaker participation
	if _, err := mongodb.Threads.DeleteThread(threadID); err != nil {
		http.Error(w, "Thread not found: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(speaker)
}

func stepSpeakerStatus(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])
	step, err := strconv.Atoi(params["step"])

	if err != nil {
		http.Error(w, "Invalid step: " + err.Error(), http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.StepStatus(speakerID, step)

	if err != nil {
		http.Error(w, "Could not update speaker status: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipationStatus,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func getSpeakerValidSteps(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	validSteps := validStepsResponse{}

	steps, err := mongodb.Speakers.GetSpeakerParticipationStatusValidSteps(speakerID)

	if err != nil {
		http.Error(w, "Speaker without participation on the current event: " + err.Error(), http.StatusBadRequest)
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
		http.Error(w, "Invalid status: " + err.Error(), http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerParticipationStatus(speakerID, *status)

	if err != nil {
		http.Error(w, "Could not update speaker status: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipationStatus,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func setSpeakerPrivateImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
		http.Error(w, fmt.Sprintf("Error parsing form: %v", err.Error()), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload: " + err.Error(), http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > config.ImageMaxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadSpeakerInternalImage(currentEvent.ID, speakerID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerInternalImage(speakerID, *url)
	if err != nil {
		http.Error(w, "Couldn't update speaker internal image: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedPrivateImage,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func setSpeakerPublicImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload: " + err.Error(), http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > config.ImageMaxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadSpeakerPublicImage(currentEvent.ID, speakerID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerPublicImage(speakerID, *url)
	if err != nil {
		http.Error(w, "Couldn't update speaker internal image: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedPublicImage,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func setSpeakerCompanyImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload: " + err.Error(), http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > config.ImageMaxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadSpeakerCompanyImage(currentEvent.ID, speakerID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.UpdateSpeakerCompanyImage(speakerID, *url)
	if err != nil {
		http.Error(w, "Couldn't update speaker internal image: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedCompanyImage,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func addSpeakerFlightInfo(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var cfid = &mongodb.CreateFlightInfoData{}

	if err := cfid.ParseBody(r.Body); err != nil {
		http.Error(w, fmt.Sprintf("Could not parse body: %s", err.Error()), http.StatusBadRequest)
		return
	}

	newFlightInfo, err := mongodb.FlightInfo.CreateFlightInfo(*cfid)

	if err != nil {
		http.Error(w, "Could not create flight info: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.AddSpeakerFlightInfo(speakerID, newFlightInfo.ID)

	if err != nil {
		http.Error(w, "Could not add flight info to speaker: " + err.Error(), http.StatusExpectationFailed)

		// delete created flight info
		if _, err := mongodb.FlightInfo.DeleteFlightInfo(newFlightInfo.ID); err != nil {
			log.Printf("error deleting flight info: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipation,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func deleteSpeakerFlightInfo(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])
	flightInfoID, _ := primitive.ObjectIDFromHex(params["flightInfoID"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	backupFlightInfo, _ := mongodb.FlightInfo.GetFlightInfo(flightInfoID)

	updatedSpeaker, err := mongodb.Speakers.RemoveSpeakerFlightInfo(speakerID, flightInfoID)
	if err != nil {
		http.Error(w, "Could not remove flight info from speaker: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	_, err = mongodb.FlightInfo.DeleteFlightInfo(flightInfoID)
	if err != nil {
		http.Error(w, "Could not delete flight info: " + err.Error(), http.StatusExpectationFailed)

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

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipation,
			Speaker: &updatedSpeaker.ID,
		})
	}
}

func addSpeakerThread(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var atd = &addThreadData{}

	if err := atd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	// create the post first
	var cpd = mongodb.CreatePostData{
		Member: credentials.ID,
		Text:   *atd.Text,
	}

	newPost, err := mongodb.Posts.CreatePost(cpd)

	if err != nil {
		http.Error(w, "Could not create post: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// if applied, create the meeting
	var meetingIDPointer *primitive.ObjectID
	if *atd.Kind == models.ThreadKindMeeting {

		if err := atd.Meeting.Validate(); err != nil {
			http.Error(w, "Invalid meeting data: " + err.Error(), http.StatusBadRequest)
			return
		}

		meeting, err := mongodb.Meetings.CreateMeeting(*atd.Meeting)

		if err != nil {
			http.Error(w, "Could not create meeting: " + err.Error(), http.StatusExpectationFailed)

			// clean up the created post
			if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
				log.Printf("error deleting post: %s\n", err.Error())
			}

			return
		}

		meetingIDPointer = &meeting.ID
	}

	// only then create the thread
	var ctd = mongodb.CreateThreadData{
		Entry:   newPost.ID,
		Meeting: meetingIDPointer,
		Kind:    *atd.Kind,
	}

	newThread, err := mongodb.Threads.CreateThread(ctd)

	if err != nil {
		http.Error(w, "Could not create thread: " + err.Error(), http.StatusExpectationFailed)

		// clean up the created post and possibly meeting
		if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
			log.Printf("error deleting post: %s\n", err.Error())
		}

		if meetingIDPointer != nil {
			if _, err := mongodb.Meetings.DeleteMeeting(*meetingIDPointer); err != nil {
				log.Printf("error deleting meeting: %s\n", err.Error())
			}
		}

		return
	}

	// and finally update the speaker participation with the created thread
	updatedSpeaker, err := mongodb.Speakers.AddThread(speakerID, newThread.ID)

	if err != nil {
		http.Error(w, "Could not add thread to speaker: " + err.Error(), http.StatusExpectationFailed)

		// clean up the created post, thread and possibly meeting
		if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
			log.Printf("error deleting post: %s\n", err.Error())
		}

		if meetingIDPointer != nil {
			if _, err := mongodb.Meetings.DeleteMeeting(*meetingIDPointer); err != nil {
				log.Printf("error deleting meeting: %s\n", err.Error())
			}
		}

		if _, err := mongodb.Threads.DeleteThread(newThread.ID); err != nil {
			log.Printf("error deleting thread: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreated,
			Speaker: &updatedSpeaker.ID,
			Thread:  &newThread.ID,
		})
	}
}

func subscribeToSpeaker(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.Subscribe(speakerID, credentials.ID)

	if err != nil {
		http.Error(w, "Could not subscribe to speaker: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func unsubscribeToSpeaker(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	speakerID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(speakerID); err != nil {
		http.Error(w, "Invalid speaker ID: " + err.Error(), http.StatusNotFound)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	updatedSpeaker, err := mongodb.Speakers.Unsubscribe(speakerID, credentials.ID)

	if err != nil {
		http.Error(w, "Could not subscribe to speaker: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedSpeaker)
}

func removeSpeakerParticipation(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Speakers.GetSpeaker(id); err != nil {
		http.Error(w, "Speaker not found: " + err.Error(), http.StatusNotFound)
		return
	}

	event, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Could not get current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	speaker, err := mongodb.Speakers.RemoveSpeakerParticipation(id, event.ID)
	if err != nil {
		http.Error(w, "Could not remove participation: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(speaker)
}
