package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getFlightInfo(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	flightInfo, err := mongodb.FlightInfo.GetFlightInfo(id)

	if err != nil {
		http.Error(w, "Could not find flight info", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(flightInfo)
}

func updateFlightInfo(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.FlightInfo.GetFlightInfo(id); err != nil {
		http.Error(w, "Could not find flight info", http.StatusNotFound)
		return
	}

	var ufid = &mongodb.CreateFlightInfoData{}

	if err := ufid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedFlightInfo, err := mongodb.FlightInfo.UpdateFlightInfo(id, *ufid)

	if err != nil {
		http.Error(w, "Could not update flight info", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedFlightInfo)
}
