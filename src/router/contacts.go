package router

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/models"
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

func addPhone(w http.ResponseWriter, r *http.Request){

	defer r.Body.Close()

	var phone models.ContactPhone

	params := mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])

	if err := json.NewDecoder(r.Body).Decode(&phone); err != nil{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}
	if len(phone.Phone) == 0{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	contact, err := mongodb.Contacts.AddPhone(id, phone)
	if err != nil{
		http.Error(w, "Could not find contact", http.StatusNotFound)
		return
	}
	json.NewEncoder(w).Encode(contact)
}

func addMail(w http.ResponseWriter, r *http.Request){

	defer r.Body.Close()

	var mail models.ContactMail

	params := mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])

	if err := json.NewDecoder(r.Body).Decode(&mail); err != nil{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}
	if len(mail.Mail) == 0{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	contact, err := mongodb.Contacts.AddMail(id, mail)
	if err != nil{
		http.Error(w, "Could not find contact", http.StatusNotFound)
		return
	}
	json.NewEncoder(w).Encode(contact)
}

func updatePhone(w http.ResponseWriter, r *http.Request){
	
	defer r.Body.Close()
	
	var data mongodb.UpdatePhonesData

	params := mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}
	for _, s := range data.Phones{
		if len(s.Phone) == 0{
			http.Error(w, "Could not parse body", http.StatusBadRequest)
			return
		}
	}

	contact, err := mongodb.Contacts.UpdatePhoneNumbers(id, data)
	if err != nil {
		http.Error(w, "Could not find contact", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(contact)
}

func updateMail(w http.ResponseWriter, r *http.Request){
	
	defer r.Body.Close()
	
	var data mongodb.UpdateMailsData

	params := mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}
	for _, s := range data.Mails{
		if len(s.Mail) == 0{
			http.Error(w, "Could not parse body", http.StatusBadRequest)
			return
		}
	}

	contact, err := mongodb.Contacts.UpdateMailList(id, data)
	if err != nil {
		http.Error(w, "Could not find contact", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(contact)
}

func updateSocials(w http.ResponseWriter, r *http.Request){
	
	defer r.Body.Close()
	
	var data models.ContactSocials

	params := mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])

	if err := json.NewDecoder(r.Body).Decode(&data); err != nil{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	contact, err := mongodb.Contacts.UpdateSocials(id, data)
	if err != nil {
		http.Error(w, "Could not find contact", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(contact)
}