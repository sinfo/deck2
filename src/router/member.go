package router

import (
	"encoding/json"
	"net/http"
	"strconv"

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

	var cmd = &mongodb.CreateMemberData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedMember, err := mongodb.Members.UpdateMember(id, *cmd)

	if err != nil {
		http.Error(w, "Could not update member", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedMember)
}

func createMemberContact(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])
	var ccd = &mongodb.CreateContactData{}

	if err := ccd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	contact, err := mongodb.Contacts.CreateContact(*ccd)
	if err != nil {
		http.Error(w, "Could not create contact", http.StatusExpectationFailed)
		return
	}

	updatedMember, err := mongodb.Members.UpdateContact(id, contact.ID)
	if err != nil {
		http.Error(w, "Could not update member", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedMember)
}

func deleteNotification(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	memberID, _ := primitive.ObjectIDFromHex(params["id"])
	var dmnd = &mongodb.DeleteNotificationData{}

	if err := json.NewDecoder(r.Body).Decode(dmnd); err != nil {
		http.Error(w, "Could not parse body.", http.StatusBadRequest)
		return
	}

	updatedMember, err := mongodb.Members.DeleteNotification(memberID, *dmnd)
	if err != nil {
		http.Error(w, "Could not delete notification", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedMember)
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

func getMemberPublic(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	member, err := mongodb.Members.GetMemberPublic(id)

	if err != nil {
		http.Error(w, "Could not find member", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(member)
}
