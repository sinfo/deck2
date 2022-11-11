package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strconv"

	"github.com/h2non/filetype"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/spaces"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)

func getMembers(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetMemberOptions{}

	name := urlQuery.Get("name")
	event := urlQuery.Get("event")
	var eventID int

	if len(name) > 0 {
		options.Name = &name
	}

	if len(event) > 0 {
		eventID, _ = strconv.Atoi(event)
		options.Event = &eventID
	}

	members, err := mongodb.Members.GetMembers(options)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(members)
}

func createMember(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var cmd = &mongodb.CreateMemberData{}

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newMember, err := mongodb.Members.CreateMember(*cmd)

	if err != nil {
		http.Error(w, "Could not create member", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newMember)
}

func getMember(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	member, err := mongodb.Members.GetMember(id)

	if err != nil {
		http.Error(w, "Could not find member", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(member)
}

func updateMember(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Members.GetMember(id); err != nil {
		http.Error(w, "Invalid member ID", http.StatusNotFound)
		return
	}

	var umd = &mongodb.UpdateMemberData{}

	if err := umd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedMember, err := mongodb.Members.UpdateMember(id, *umd)

	if err != nil {
		http.Error(w, "Could not update member", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedMember)
}

func setMemberImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	memberID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Members.GetMember(memberID); err != nil {
		http.Error(w, "Invalid member ID", http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
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

	url, err := spaces.UploadMemberImage(currentEvent.ID, memberID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedMember, err := mongodb.Members.UpdateImage(memberID, *url)
	if err != nil {
		http.Error(w, "Couldn't update member internal image", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedMember)
}

func deleteMember(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	deletedMember, err := mongodb.Members.DeleteMember(id)
	if err != nil {
		if err.Error() == mongodb.MemberAssociated {
			http.Error(w, "Error deleting member: "+err.Error(), http.StatusNotAcceptable)
		} else {
			http.Error(w, "Error deleting member: "+err.Error(), http.StatusNotFound)
		}
		return
	}

	json.NewEncoder(w).Encode(deletedMember)
}

type roleData struct {
	Role models.TeamRole `json:"role"`
}

func getMemberRole(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	member, err := mongodb.Members.GetMember(id)
	if err != nil {
		http.Error(w, "Member not found: "+err.Error(), http.StatusNotFound)
		return
	}

	credentials, err := mongodb.Members.GetMemberAuthCredentials(member.SINFOID)
	if err != nil {
		http.Error(w, "Error getting member credentials: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	roleData := roleData{}
	roleData.Role = credentials.Role

	json.NewEncoder(w).Encode(roleData)
}

func getMembersParticipations(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	membersEventsTeams, err := mongodb.Members.GetMembersParticipations(id)
	if err != nil {
		http.Error(w, "Member not found: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(membersEventsTeams)
}

// PUBLIC ENDPOINTS

func getMembersPublic(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetMemberOptions{}

	name := urlQuery.Get("name")
	event := urlQuery.Get("event")
	var eventID int

	if len(name) > 0 {
		options.Name = &name
	}
	if len(event) > 0 {
		eventID, _ = strconv.Atoi(event)
		options.Event = &eventID
	}

	members, err := mongodb.Members.GetMembersPublic(options)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(members)
}
