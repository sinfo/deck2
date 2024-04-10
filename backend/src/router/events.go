package router

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	ics "github.com/arran4/golang-ical"
	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/spaces"
	"go.mongodb.org/mongo-driver/bson/primitive"
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
			http.Error(w, "Invalid date format (before): " + err.Error(), http.StatusBadRequest)
			return
		}

		options.Before = &beforeDate
	}

	if len(after) > 0 {
		afterDate, err := time.Parse(time.RFC3339, after)

		if err != nil {
			http.Error(w, "Invalid date format (after): " + err.Error(), http.StatusBadRequest)
			return
		}

		options.After = &afterDate
	}

	if len(during) > 0 {
		duringDate, err := time.Parse(time.RFC3339, during)

		if err != nil {
			http.Error(w, "Invalid date format (during): " + err.Error(), http.StatusBadRequest)
			return
		}

		options.During = &duringDate
	}

	events, err := mongodb.Events.GetEvents(options)

	if err != nil {
		http.Error(w, "Unable to make query do database: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(events)
}

func getEventsPublic(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetPublicEventsOptions{}

	current := urlQuery.Get("current")
	pastEvents := urlQuery.Get("pastEvents")

	if currentValue, err := strconv.ParseBool(current); err == nil {
		options.Current = &currentValue
	}

	if pastEventsValue, err := strconv.ParseBool(pastEvents); err == nil {
		options.PastEvents = &pastEventsValue
	}

	events, err := mongodb.Events.GetPublicEvents(options)

	if err != nil {
		http.Error(w, "Unable to make query do database: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(events)
}

func getLatestEvent(w http.ResponseWriter, r *http.Request){
	event, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Could not find latest event: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(event)
}

func getEvent(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, errConverter := strconv.Atoi(params["id"])

	if errConverter != nil {
		http.Error(w, "Could not find event: " + errConverter.Error(), http.StatusNotFound)
		return
	}

	event, err := mongodb.Events.GetEvent(id)

	if err != nil {
		http.Error(w, "Could not find event: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(event)
}

func createEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ced = &mongodb.CreateEventData{}

	if err := ced.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newEvent, err := mongodb.Events.CreateEvent(*ced)

	if err != nil {
		http.Error(w, "Could not create event: " + err.Error(), http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newEvent)
}

func updateEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	var ued = &mongodb.UpdateEventData{}

	if err := ued.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedEvent, err := mongodb.Events.UpdateEvent(currentEvent.ID, *ued)

	if err != nil {
		http.Error(w, "Could not update event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func deleteEvent(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, errConverter := strconv.Atoi(params["id"])

	if errConverter != nil {
		http.Error(w, "Could not convert event ID to integer: " + errConverter.Error(), http.StatusNotFound)
		return
	}

	event, err := mongodb.Events.DeleteEvent(id)

	if err != nil {
		http.Error(w, "Could not delete event: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(event)
}

func updateEventThemes(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	var uetd = &mongodb.UpdateEventThemesData{}

	if err := uetd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	days, err := currentEvent.DurationInDays()

	if err != nil {
		http.Error(w, "Event without dates yet: " + err.Error(), http.StatusBadRequest)
		return
	}

	// must be bigger than 0, you can set the themes to an empty string (in case you messed up)
	if uetd.Themes != nil && len(*uetd.Themes) > 0 && len(*uetd.Themes) != days {
		http.Error(w, fmt.Sprintf("Number of themes must be equal to the event's duration (%v days).", days), http.StatusBadRequest)
		return
	}

	updatedEvent, err := mongodb.Events.UpdateThemes(currentEvent.ID, *uetd)

	if err != nil {
		http.Error(w, "Could not update event's themes: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func addPackageToEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	var aepd = &mongodb.AddEventPackageData{}

	if err := aepd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Packages.GetPackage(*aepd.Template); err != nil {
		http.Error(w, "Package not found: " + err.Error(), http.StatusNotFound)
		return
	}

	newEvent, err := mongodb.Events.AddPackage(currentEvent.ID, *aepd)

	if err != nil {
		http.Error(w, "Could not save package on event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newEvent)
}

func removePackageFromEvent(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	packageID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	newEvent, err := mongodb.Events.RemovePackage(currentEvent.ID, packageID)

	if err != nil {
		http.Error(w, "Could not remove package from the current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newEvent)
}

func updatePackageFromEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	packageID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	var uepd = &mongodb.UpdateEventPackageData{}

	if err := uepd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newEvent, err := mongodb.Events.UpdatePackage(currentEvent.ID, packageID, *uepd)

	if err != nil {
		http.Error(w, "Could not update template on the current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newEvent)
}

func addItemToEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	var aeid = &mongodb.AddEventItemData{}

	if err := aeid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	if _, err = mongodb.Items.GetItem(*aeid.ItemID); err != nil {
		http.Error(w, "Could not find item: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedEvent, err := mongodb.Events.AddItem(currentEvent.ID, *aeid)

	if err != nil {
		http.Error(w, "Could not save item on event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func removeItemToEvent(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	itemID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedEvent, err := mongodb.Events.RemoveItem(currentEvent.ID, itemID)

	if err != nil {
		http.Error(w, "Could not remove item from event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func addSessionToEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	var csd = &mongodb.CreateSessionData{}

	if err := csd.ParseBody(r.Body); err != nil {
		http.Error(w, fmt.Sprintf("Could not parse body: %v", err.Error()), http.StatusBadRequest)
		return
	}

	createdSession, err := mongodb.Sessions.CreateSession(*csd)

	if err != nil {
		http.Error(w, "Could not create session: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	updatedEvent, err := mongodb.Events.AddSession(currentEvent.ID, createdSession.ID)

	if err != nil {
		http.Error(w, "Could not save session on event: " + err.Error(), http.StatusExpectationFailed)

		// delete created session
		if _, err = mongodb.Sessions.DeleteSession(createdSession.ID); err != nil {
			log.Println("Error removing session: " + err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedEvent)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreated,
			Session: &createdSession.ID,
		})
	}
}

func addMeetingToEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	var cmd = &mongodb.CreateMeetingData{}

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newMeeting, err := mongodb.Meetings.CreateMeeting(*cmd)
	if err != nil {
		http.Error(w, "Could not create a new meeting: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	updatedEvent, err := mongodb.Events.AddMeeting(currentEvent.ID, newMeeting.ID)

	if err != nil {
		http.Error(w, "Could not save meeting on event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func removeMeetingFromEvent(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	meetingID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: " + err.Error(), http.StatusNotFound)
		return
	}

	if _, err = mongodb.Meetings.GetMeeting(meetingID); err != nil {
		http.Error(w, "Could not find meeting: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedEvent, err := mongodb.Events.RemoveMeeting(currentEvent.ID, meetingID)

	if err != nil {
		http.Error(w, "Could not remove meeting from event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	if _, err = mongodb.Meetings.DeleteMeeting(meetingID); err != nil {
		http.Error(w, "Could not delete meeting: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func removeTeamFromEvent(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	teamID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event: "+err.Error(), http.StatusNotFound)
		return
	}

	if _, err = mongodb.Teams.GetTeam(teamID); err != nil {
		http.Error(w, "Could not find team: "+err.Error(), http.StatusNotFound)
		return
	}

	updatedEvent, err := mongodb.Events.RemoveTeam(currentEvent.ID, teamID)

	if err != nil {
		http.Error(w, "Could not remove team from event: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func updateCalendar(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Could not find current event: "+err.Error(), http.StatusNotFound)
		return
	}

	sessions, err := mongodb.Sessions.GetPublicSessions(mongodb.GetSessionsPublicOptions{})
	if err != nil {
		http.Error(w, "Could not get sessions: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	calendar := ics.NewCalendar()
	calendar.SetMethod(ics.MethodRequest)
	calendar.SetProductId("-//deck.sinfo.org//deck//EN")
	calendar.SetXWRCalName(fmt.Sprintf("SINFO %d Sessions", currentEvent.ID))
	calendar.SetVersion("3.0")

	for _, session := range sessions {
		event := calendar.AddEvent(fmt.Sprintf("sinfo-%d-%s", currentEvent.ID, session.ID.Hex()))
		event.SetCreatedTime(time.Now())
		event.SetDtStampTime(time.Now())

		// makes session names more readable
		kind := session.Kind
		sessionKind := "Session"

		if kind == "TALK" {
			sessionKind = "Keynote"
		} else if kind == "WORKSHOP" {
			sessionKind = "Workshop"
		} else if kind == "PRESENTATION" {
			sessionKind = "Presentation"
		}

		// sets summary of event differently depending on the kind of session
		if kind == "WORKSHOP" || kind == "PRESENTATION" {
			event.SetSummary(fmt.Sprintf("%s - %s", session.CompanyPublic.Name, sessionKind))
		} else {
			speakerNames := ""

			// in case of a panel with more than one speaker
			for _, speaker := range *session.SpeakersPublic {
				speakerNames += speaker.Name + ", "
			}

			// remove last comma
			speakerNames = speakerNames[:len(speakerNames)-2]

			event.SetSummary(fmt.Sprintf("%s - %s", speakerNames, sessionKind))
		}

		event.SetDescription(fmt.Sprintf("%s Title:\n%s\n\nDescription:\n%s", sessionKind, session.Title, session.Description))
		event.SetLocation(session.Place)
		event.SetStartAt(session.Begin)
		event.SetEndAt(session.End)
	}

	// get size of calendar file
	calendarString := calendar.Serialize()
	calendarReader := strings.NewReader(calendarString)
	size := int64(calendarReader.Len())

	url, err := spaces.UploadCalendarFile(currentEvent.ID, calendarReader, size, "text/calendar")
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedEvent, err := mongodb.Events.UpdateCalendar(currentEvent.ID, *url)
	if err != nil {
		http.Error(w, "Could not update event's calendar: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func getEventCalendar(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find event: "+err.Error(), http.StatusNotFound)
		return
	}

	// check if calendar file exists
	if currentEvent.CalendarUrl == "" {
		http.Error(w, "Calendar file not found", http.StatusNotFound)
		return
	}

	http.Redirect(w, r, currentEvent.CalendarUrl, http.StatusPermanentRedirect)
}
