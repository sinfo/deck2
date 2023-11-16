package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getCompanyReps(w http.ResponseWriter, r *http.Request) {
	urlQuery := r.URL.Query()

	companyID := urlQuery.Get("company")
	if companyID == "" {
		http.Error(w, "Company ID is required", http.StatusBadRequest)
		return
	}

	// Parse the `companyID` to a valid ObjectID
	parsedCompanyID, err := primitive.ObjectIDFromHex(companyID)
	if err != nil {
		http.Error(w, "Invalid company ID", http.StatusBadRequest)
		return
	}

	// Retrieve the list of employer IDs from the Company document
	company, err := mongodb.Companies.GetCompany(parsedCompanyID)
	if err != nil {
		http.Error(w, "Unexpected error: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	employerIDs := company.Employers
	print(employerIDs)
	// Initialize a slice to store the representatives
	reps := make([]*models.CompanyRep, 0)

	// Iterate through the representative IDs and fetch each representative
	for _, repID := range employerIDs {
		rep, err := mongodb.CompanyReps.GetCompanyRep(repID)
		if err != nil {
			http.Error(w, "Unexpected error: "+err.Error(), http.StatusExpectationFailed)
			return
		}
		reps = append(reps, rep)
	}

	json.NewEncoder(w).Encode(reps)
}

func getCompanyRep(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	repID, _ := primitive.ObjectIDFromHex(params["id"])

	rep, err := mongodb.CompanyReps.GetCompanyRep(repID)
	if err != nil {
		http.Error(w, "CompanyRep not found: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(rep)
}

func updateCompanyRep(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	repID, _ := primitive.ObjectIDFromHex(params["id"])

	var ccrd = mongodb.CreateCompanyRepData{}

	if err := json.NewDecoder(r.Body).Decode(&ccrd); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	rep, err := mongodb.CompanyReps.UpdateCompanyRep(repID, ccrd)
	if err != nil {
		http.Error(w, "CompanyRep not found: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(rep)
}
