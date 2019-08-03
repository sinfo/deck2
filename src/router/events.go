package router

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
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

func getEvent(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, errConverter := strconv.Atoi(params["id"])

	if errConverter != nil {
		http.Error(w, "Could not find event", http.StatusNotFound)
		return
	}

	event, err := mongodb.Events.GetEvent(id)

	if err != nil {
		http.Error(w, "Could not find event", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(event)
}

func createEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ced = &mongodb.CreateEventData{}

	if err := ced.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newEvent, err := mongodb.Events.CreateEvent(*ced)

	if err != nil {
		http.Error(w, "Could not create event", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newEvent)
}

func updateEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusExpectationFailed)
		return
	}

	var ued = &mongodb.UpdateEventData{}

	if err := ued.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedEvent, err := mongodb.Events.UpdateEvent(currentEvent.ID, *ued)

	if err != nil {
		http.Error(w, "Could not update event", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func deleteEvent(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, errConverter := strconv.Atoi(params["id"])

	if errConverter != nil {
		http.Error(w, "Could not convert event ID to integer", http.StatusNotFound)
		return
	}

	event, err := mongodb.Events.DeleteEvent(id)

	if err != nil {
		http.Error(w, "Could not delete event", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(event)
}

func updateEventThemes(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	var uetd = &mongodb.UpdateEventThemesData{}

	if err := uetd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	days, err := currentEvent.DurationInDays()

	if err != nil {
		http.Error(w, "Event without dates yet.", http.StatusBadRequest)
		return
	}

	// must be bigger than 0, you can set the themes to an empty string (in case you messed up)
	if uetd.Themes != nil && len(*uetd.Themes) > 0 && len(*uetd.Themes) != days {
		http.Error(w, fmt.Sprintf("Number of themes must be equal to the event's duration (%v days).", days), http.StatusBadRequest)
		return
	}

	updatedEvent, err := mongodb.Events.UpdateThemes(currentEvent.ID, *uetd)

	if err != nil {
		http.Error(w, "Could not update event's themes", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}
