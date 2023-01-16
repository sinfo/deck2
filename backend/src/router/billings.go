package router

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)

func getBillings(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetBillingsOptions{}

	after := urlQuery.Get("after")
	before := urlQuery.Get("before")
	valueGreaterThan := urlQuery.Get("valueGreaterThan")
	valueLessThan := urlQuery.Get("valueLessThan")
	event := urlQuery.Get("event")
	company := urlQuery.Get("company")

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	options.Role = &credentials.Role

	if len(after) > 0 {
		afterDate, err := time.Parse(time.RFC3339, after)

		if err != nil {
			http.Error(w, "Invalid date format (after)", http.StatusBadRequest)
			return
		}

		options.After = &afterDate
	}

	if len(before) > 0 {
		beforeDate, err := time.Parse(time.RFC3339, before)

		if err != nil {
			http.Error(w, "Invalid date format (before)", http.StatusBadRequest)
			return
		}

		options.Before = &beforeDate
	}

	if len(valueGreaterThan) > 0 {
		vgt, err := strconv.Atoi(valueGreaterThan)

		if err != nil {
			http.Error(w, "Invalid value (greater)", http.StatusBadRequest)
			return
		}

		options.ValueGreaterThan = &vgt
	}

	if len(valueLessThan) > 0 {
		vlt, err := strconv.Atoi(valueLessThan)

		if err != nil {
			http.Error(w, "Invalid value (less)", http.StatusBadRequest)
			return
		}

		options.ValueLessThan = &vlt
	}

	if len(event) > 0 {
		eventInt, err := strconv.Atoi(event)

		if err != nil {
			http.Error(w, "Invalid value (event)", http.StatusBadRequest)
			return
		}

		options.Event = &eventInt
	}

	if len(company) > 0 {

		companyID, err := primitive.ObjectIDFromHex(company)
		if err != nil {
			http.Error(w, "Invalid value (company)", http.StatusBadRequest)
			return
		}

		options.Company = &companyID
	}

	billings, err := mongodb.Billings.GetBillings(options)
	if err != nil {
		http.Error(w, "unexpected error found", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(billings)
}

func getBilling(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	billingID, _ := primitive.ObjectIDFromHex(params["id"])

	billing, err := mongodb.Billings.GetBilling(billingID)
	if err != nil {
		http.Error(w, "Billing not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(billing)
}

func updateBilling(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	billingID, _ := primitive.ObjectIDFromHex(params["id"])

	var cbd = &mongodb.CreateBillingData{}

	if err := cbd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	newBilling, err := mongodb.Billings.UpdateBilling(billingID, *cbd)
	if err != nil {
		http.Error(w, "Billing not found: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(newBilling)
}
