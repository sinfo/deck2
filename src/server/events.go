package server

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/sinfo/deck2/src/mongodb"
)

func getEvents(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetEventsOptions{}

	name := urlQuery.Get("name")
	before := urlQuery.Get("before")
	after := urlQuery.Get("after")
	during := urlQuery.Get("during")

	if len(name) > 0 {
		options.Name = &name
	}

	if len(before) > 0 {
		beforeDate, err := time.Parse(time.RFC3339, before)

		if err != nil {
			http.Error(w, "Invalid date format (before)", http.StatusBadRequest)
			return
		}

		options.Before = &beforeDate
	}

	if len(after) > 0 {
		afterDate, err := time.Parse(time.RFC3339, after)

		if err != nil {
			http.Error(w, "Invalid date format (after)", http.StatusBadRequest)
			return
		}

		options.After = &afterDate
	}

	if len(during) > 0 {
		duringDate, err := time.Parse(time.RFC3339, during)

		if err != nil {
			http.Error(w, "Invalid date format (during)", http.StatusBadRequest)
			return
		}

		options.During = &duringDate
	}

	events, err := mongodb.Events.GetEvents(options)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(events)
}
