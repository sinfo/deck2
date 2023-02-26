package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/h2non/filetype"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/spaces"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getMe(w http.ResponseWriter, r *http.Request) {

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	memberID := credentials.ID

	member, err := mongodb.Members.GetMember(memberID)

	if err != nil {
		http.Error(w, "Could not find member: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(member)
}

func setMyImage(w http.ResponseWriter, r *http.Request) {

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	memberID := credentials.ID

	if _, err := mongodb.Members.GetMember(memberID); err != nil {
		http.Error(w, "Invalid member ID: " + err.Error(), http.StatusNotFound)
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

	url, err := spaces.UploadMemberImage(currentEvent.ID, memberID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedMember, err := mongodb.Members.UpdateImage(memberID, *url)
	if err != nil {
		http.Error(w, "Couldn't update member's image: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedMember)
}

func updateMe(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var umd = &mongodb.UpdateMemberData{}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	memberID := credentials.ID

	if err := umd.ParseBody(r.Body); err != nil {
		http.Error(w, fmt.Sprintf("Could not parse body: %v", err.Error()), http.StatusBadRequest)
		return
	}

	updatedMember, err := mongodb.Members.UpdateMember(memberID, *umd)

	if err != nil {
		http.Error(w, "Could not update me: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedMember)
}

func getMyNotifications(w http.ResponseWriter, r *http.Request) {

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	memberID := credentials.ID

	if _, err := mongodb.Members.GetMember(memberID); err != nil {
		http.Error(w, "Could not find member: " + err.Error(), http.StatusNotFound)
		return
	}

	notifications, err := mongodb.Notifications.GetMemberNotifications(memberID)
	if err != nil {
		http.Error(w, "Could not find get notifications: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(notifications)
}

func deleteMyNotification(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	memberID := credentials.ID

	if _, err := mongodb.Members.GetMember(memberID); err != nil {
		http.Error(w, "Could not find member: " + err.Error(), http.StatusNotFound)
		return
	}

	if _, err := mongodb.Notifications.GetNotification(id); err != nil {
		http.Error(w, "Notification not found: " + err.Error(), http.StatusNotFound)
		return
	}

	notification, err := mongodb.Notifications.DeleteNotification(id)
	if err != nil {
		http.Error(w, "Could not delete notification: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(notification)
}
