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

func getCompanies(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetCompaniesOptions{}

	event := urlQuery.Get("event")
	partner := urlQuery.Get("partner")
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

	if len(partner) > 0 {
		isPartner, err := strconv.ParseBool(partner)
		if err != nil {
			http.Error(w, "Invalid partner format", http.StatusBadRequest)
			return
		}
		options.IsPartner = &isPartner
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

	companies, err := mongodb.Companies.GetCompanies(options)

	if err != nil {
		http.Error(w, "Unable to get companies", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(companies)
}

func createCompany(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ccd = &mongodb.CreateCompanyData{}

	if err := ccd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newCompany, err := mongodb.Companies.CreateCompany(*ccd)

	if err != nil {
		http.Error(w, "Could not create company", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newCompany)
}

func addCompanyParticipation(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	var apd = &mongodb.AddParticipationData{}

	if err := apd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(companyID, credentials.ID, *apd)

	if err != nil {
		http.Error(w, "Could not add participation to company", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)
}
