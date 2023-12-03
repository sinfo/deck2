package router

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getFlightInfo(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	flightInfo, err := mongodb.FlightInfo.GetFlightInfo(id)

	if err != nil {
		http.Error(w, "Could not find flight info: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(flightInfo)
}

func getFlightsInfo(w http.ResponseWriter, r *http.Request) {

  urlQuery := r.URL.Query()
  options := mongodb.GetFlightsInfoOptions{}

  event := urlQuery.Get("event")
  speaker := urlQuery.Get("speaker")
  from := urlQuery.Get("from")
  to := urlQuery.Get("to")

  if len(event) > 0 {
    eventID, err := strconv.Atoi(event)
    if err != nil {
      http.Error(w, "Invalid event ID format: " + err.Error(), http.StatusBadRequest)
      return
    }
    options.Event = &eventID
  }

  if len(speaker) > 0 {
    speakerID, err := primitive.ObjectIDFromHex(speaker)
    if err != nil {
      http.Error(w, "Invalid speaker ID format: " + err.Error(), http.StatusBadRequest)
      return
    }
    options.Speaker = &speakerID
  }

  if len(from) > 0 {
    options.From = &from
  }

  if len(to) > 0 {
    options.To = &to
  }

  flightsInfo, err := mongodb.FlightInfo.GetFlightsInfo(options)

  if err != nil {
    http.Error(w, "Could not find flights info: " + err.Error(), http.StatusNotFound)
    return
  }

  json.NewEncoder(w).Encode(flightsInfo)
}

func updateFlightInfo(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.FlightInfo.GetFlightInfo(id); err != nil {
		http.Error(w, "Could not find flight info: " + err.Error(), http.StatusNotFound)
		return
	}

	var ufid = &mongodb.CreateFlightInfoData{}

	if err := ufid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedFlightInfo, err := mongodb.FlightInfo.UpdateFlightInfo(id, *ufid)

	if err != nil {
		http.Error(w, "Could not update flight info: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedFlightInfo)
}
