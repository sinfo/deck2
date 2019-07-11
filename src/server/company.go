package server

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
)

func getCompanies(w http.ResponseWriter, r *http.Request) {

	query := bson.M{}

	companies, err := mongodb.Companies.GetCompanies(query)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
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
