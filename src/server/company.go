package server

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
)

func GetCompanies(w http.ResponseWriter, r *http.Request) {

	query := bson.M{}

	companies, err := mongodb.Companies.GetCompanies(query)

	if err != nil {
		log.Fatal(err)
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(companies)
}

func CreateCompany(w http.ResponseWriter, r *http.Request) {

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
