package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getCompanyReps(w http.ResponseWriter, r *http.Request) {
	urlQuery := r.URL.Query()

	name := urlQuery.Get("name")

	gcro := mongodb.GetCompanyRepOptions{}

	if len(name) > 0 {
		gcro.Name = &name
	}

	reps, err := mongodb.CompanyReps.GetCompanyReps(gcro)
	if err != nil {
		http.Error(w, "Unexpected error: "+err.Error(), http.StatusExpectationFailed)
		return
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
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	rep, err := mongodb.CompanyReps.UpdateCompanyRep(repID, ccrd)
	if err != nil {
		http.Error(w, "CompanyRep not found: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(rep)
}
