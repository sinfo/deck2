package router

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)

func getContacts(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetContactsOptions{}

	phone := urlQuery.Get("phone")
	mail := urlQuery.Get("mail")

	if len(phone) >0 {
		options.Phone = &phone
	}

	if len(mail) >0 {
		options.Mail = &mail
	}

	contacts, err := mongodb.Contacts.GetContacts(options)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(contacts)
}

func updateContact(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params :=mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])

	var ccd = &mongodb.CreateContactData{}

	if err := ccd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newContact, err := mongodb.Contacts.UpdateContact(id,*ccd)

	if err != nil {
		http.Error(w, "Could not update contact", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(newContact)
}

func getContact(w http.ResponseWriter, r *http.Request) {
	params :=mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])
	
	contact, err := mongodb.Contacts.GetContact(id)

	if err != nil {
		http.Error(w, "Could not find contact", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(contact)
}
