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

	"github.com/h2non/filetype"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/spaces"
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
		http.Error(w, "Could not find meeting", http.StatusNotFound)
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
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
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

func addMeetingThread(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	meetingID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Meetings.GetMeeting(meetingID); err != nil {
		http.Error(w, "Invalid meeting ID", http.StatusNotFound)
		return
	}

	var atd = &addThreadData{}

	if err := atd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
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
		http.Error(w, "Could not create post", http.StatusExpectationFailed)
		return
	}

	// assuming that meeting is already created
	if *atd.Kind != models.ThreadKindMeeting {
		http.Error(w, "Kind of thread must be meeting", http.StatusInternalServerError)
		return
	}

	// create the thread
	var ctd = mongodb.CreateThreadData{
		Entry: newPost.ID,
		Kind:  *atd.Kind,
	}

	newThread, err := mongodb.Threads.CreateThread(ctd)

	if err != nil {
		http.Error(w, "Could not create thread", http.StatusExpectationFailed)

		// clean up the created post
		if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
			log.Printf("error deleting post: %s\n", err.Error())
		}

		return
	}

	// and finally update the meeting participation with the created thread
	updatedMeeting, err := mongodb.Meetings.AddThread(meetingID, newThread.ID)

	if err != nil {
		http.Error(w, "Could not add thread to meeting", http.StatusExpectationFailed)

		// clean up the created post and thread
		if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
			log.Printf("error deleting post: %s\n", err.Error())
		}

		if _, err := mongodb.Threads.DeleteThread(newThread.ID); err != nil {
			log.Printf("error deleting thread: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedMeeting)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreated,
			Speaker: &updatedMeeting.ID,
			Thread:  &newThread.ID,
		})
	}
}

func deleteMeetingThread(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])
	threadID, _ := primitive.ObjectIDFromHex(params["threadID"])

	_, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	// Delete thread and posts (comments) associated to it
	if _, err := mongodb.Threads.DeleteThread(threadID); err != nil {
		http.Error(w, "Thread not found", http.StatusNotFound)
		return
	}

	meeting, err := mongodb.Meetings.DeleteMeetingThread(id, threadID)
	if err != nil {
		http.Error(w, "Meeting or thread not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(meeting)
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

func updateMeeting(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	var umd = mongodb.UpdateMeetingData{}

	if _, err := mongodb.Meetings.GetMeeting(id); err != nil {
		http.Error(w, "Could not find meeting", http.StatusNotFound)
		return
	}

	if err := umd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	meeting, err := mongodb.Meetings.UpdateMeeting(umd, id)
	if err != nil {
		http.Error(w, "Could not update meeting", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(meeting)
}

func uploadMeetingMinute(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	meetingID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Meetings.GetMeeting(meetingID); err != nil {
		http.Error(w, "Invalid meeting ID", http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.MinuteMaxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.MinuteMaxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("minute")
	if err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > config.MinuteMaxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.MinuteMaxSize), http.StatusBadRequest)
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

	if !filetype.IsExtension(bytes, "pdf") {
		http.Error(w, "Not a pdf", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	log.Println(kind)
	if err != nil {
		http.Error(w, "Unable to get file type", http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadMeetingMinute(currentEvent.ID, meetingID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedMeeting, err := mongodb.Meetings.UploadMeetingMinute(meetingID, *url)
	if err != nil {
		http.Error(w, "Couldn't update speaker internal image", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedMeeting)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUploadedMeetingMinute,
			Meeting: &updatedMeeting.ID,
		})
	}
}

func deleteMeetingMinute(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	meetingID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Meetings.GetMeeting(meetingID); err != nil {
		http.Error(w, "Invalid meeting ID", http.StatusNotFound)
		return
	}

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event", http.StatusExpectationFailed)
		return
	}

	err = spaces.DeleteMeetingMinute(currentEvent.ID, meetingID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedMeeting, err := mongodb.Meetings.DeleteMeetingMinute(meetingID)
	if err != nil {
		http.Error(w, "Couldn't delete meeting minutes", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedMeeting)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindDeletedMeetingMinute,
			Meeting: &updatedMeeting.ID,
		})
	}
}

func addMeetingParticipant(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	meetingID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Meetings.GetMeeting(meetingID); err != nil {
		http.Error(w, "Invalid meeting ID", http.StatusNotFound)
		return
	}

	var cmd = mongodb.MeetingParticipantData{}

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	meeting, err := mongodb.Meetings.AddMeetingParticipant(meetingID, cmd)
	if err != nil {
		http.Error(w, "Could not add participant to meeting", http.StatusExpectationFailed)
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

func deleteMeetingParticipant(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	meetingID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Meetings.GetMeeting(meetingID); err != nil {
		http.Error(w, "Invalid meeting ID", http.StatusNotFound)
		return
	}

	var cmd = mongodb.MeetingParticipantData{}

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	meeting, err := mongodb.Meetings.DeleteMeetingParticipant(meetingID, cmd)
	if err != nil {
		http.Error(w, "Could not add participant to meeting", http.StatusExpectationFailed)
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
