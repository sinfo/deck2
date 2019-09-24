package router

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"golang.org/x/oauth2"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/option"
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
		http.Error(w, "Could not update event", http.StatusExpectationFailed)
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
		http.Error(w, "Could not update event's themes", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func addPackageToEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	var aepd = &mongodb.AddEventPackageData{}

	if err := aepd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Packages.GetPackage(*aepd.Template); err != nil {
		http.Error(w, "Package not found", http.StatusNotFound)
		return
	}

	newEvent, err := mongodb.Events.AddPackage(currentEvent.ID, *aepd)

	if err != nil {
		http.Error(w, "Could not save package on event", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newEvent)
}

func removePackageFromEvent(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	packageID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	newEvent, err := mongodb.Events.RemovePackage(currentEvent.ID, packageID)

	if err != nil {
		http.Error(w, "Could not remove package from the current event", http.StatusExpectationFailed)
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
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	var uepd = &mongodb.UpdateEventPackageData{}

	if err := uepd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newEvent, err := mongodb.Events.UpdatePackage(currentEvent.ID, packageID, *uepd)

	if err != nil {
		http.Error(w, "Could not update template on the current event", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newEvent)
}

func addItemToEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	var aeid = &mongodb.AddEventItemData{}

	if err := aeid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	if _, err = mongodb.Items.GetItem(*aeid.ItemID); err != nil {
		http.Error(w, "Could not find item", http.StatusNotFound)
		return
	}

	updatedEvent, err := mongodb.Events.AddItem(currentEvent.ID, *aeid)

	if err != nil {
		http.Error(w, "Could not save item on event", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func removeItemToEvent(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	itemID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	updatedEvent, err := mongodb.Events.RemoveItem(currentEvent.ID, itemID)

	if err != nil {
		http.Error(w, "Could not remove item from event", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func addSessionToEvent(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	var csd = &mongodb.CreateSessionData{}

	if err := csd.ParseBody(r.Body); err != nil {
		http.Error(w, fmt.Sprintf("Could not parse body: %v", err.Error()), http.StatusBadRequest)
		return
	}

	createdSession, err := mongodb.Sessions.CreateSession(*csd)

	if err != nil {
		http.Error(w, "Could not create session", http.StatusExpectationFailed)
		return
	}

	updatedEvent, err := mongodb.Events.AddSession(currentEvent.ID, createdSession.ID)

	if err != nil {
		http.Error(w, "Could not save session on event", http.StatusExpectationFailed)

		// delete created session
		if _, err = mongodb.Sessions.DeleteSession(createdSession.ID); err != nil {
			log.Println("Error removing session")
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
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	var cmd = &mongodb.CreateMeetingData{}

	if err := cmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newMeeting, err := mongodb.Meetings.CreateMeeting(*cmd)
	if err != nil {
		http.Error(w, "Could not create a new meeting", http.StatusExpectationFailed)
		return
	}

	updatedEvent, err := mongodb.Events.AddMeeting(currentEvent.ID, newMeeting.ID)

	if err != nil {
		http.Error(w, "Could not save meeting on event", http.StatusExpectationFailed)
		return
	}

	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {

		ctx := context.Background()

		token, err := mongodb.Tokens.GetToken(credentials.Token)
		if err != nil {
			http.Error(w, "Could not find token in database", http.StatusNotFound)
			return
		}

		newToken := new(oauth2.Token)
		newToken.Expiry = token.Expiry
		newToken.RefreshToken = token.Refresh
		newToken.AccessToken = token.Access

		client := auth.OauthConfig.Client(ctx, newToken)

		calendarService, err := calendar.NewService(ctx, option.WithHTTPClient(client))
		if err != nil {
			http.Error(w, "Could not start calendar: "+err.Error(), http.StatusExpectationFailed)
			return
		}

		calendarList, err := calendarService.CalendarList.List().Do()
		if err != nil {
			http.Error(w, "Could not list calendars"+err.Error(), http.StatusExpectationFailed)
			return
		}

		var calendarID string

		for _, s := range calendarList.Items {
			if s.Summary == "SINFO General Calendar" {
				calendarID = s.Id
			}
		}

		newEvent := &calendar.Event{
			AnyoneCanAddSelf: true,
			Id:               newMeeting.ID.Hex(),
			Location:         newMeeting.Place,
			Summary:          "Event meeting",
			Start:            &calendar.EventDateTime{DateTime: newMeeting.Begin.Format(time.RFC3339)},
			End:              &calendar.EventDateTime{DateTime: newMeeting.End.Format(time.RFC3339)},
		}

		createdEvent, err := calendarService.Events.Insert(calendarID, newEvent).Do()
		if err != nil {
			http.Error(w, "Could not add event to calendar", http.StatusExpectationFailed)
			return
		}

		log.Printf("Created event %s starting at %s", createdEvent.Summary, createdEvent.Start)
	}

	json.NewEncoder(w).Encode(updatedEvent)
}

func removeMeetingFromEvent(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	meetingID, _ := primitive.ObjectIDFromHex(params["id"])

	currentEvent, err := mongodb.Events.GetCurrentEvent()

	if err != nil {
		http.Error(w, "Could not find current event", http.StatusNotFound)
		return
	}

	if _, err = mongodb.Meetings.GetMeeting(meetingID); err != nil {
		http.Error(w, "Could not find meeting", http.StatusNotFound)
		return
	}

	updatedEvent, err := mongodb.Events.RemoveMeeting(currentEvent.ID, meetingID)

	if err != nil {
		http.Error(w, "Could not remove meeting from event", http.StatusExpectationFailed)
		return
	}

	if _, err = mongodb.Meetings.DeleteMeeting(meetingID); err != nil {
		http.Error(w, "Could not delete meeting", http.StatusExpectationFailed)
		return
	}

	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {

		ctx := context.Background()
		token, err := mongodb.Tokens.GetToken(credentials.Token)
		if err != nil {
			http.Error(w, "Could not find token in database", http.StatusNotFound)
			return
		}

		newToken := new(oauth2.Token)
		newToken.Expiry = token.Expiry
		newToken.RefreshToken = token.Refresh
		newToken.AccessToken = token.Access

		client := auth.OauthConfig.Client(ctx, newToken)

		calendarService, err := calendar.NewService(ctx, option.WithHTTPClient(client))
		if err != nil {
			http.Error(w, "Could not start calendar: "+err.Error(), http.StatusExpectationFailed)
			return
		}

		calendarList, err := calendarService.CalendarList.List().Do()
		if err != nil {
			http.Error(w, "Could not list calendars"+err.Error(), http.StatusExpectationFailed)
			return
		}

		var calendarID string

		for _, s := range calendarList.Items {
			if s.Summary == "SINFO General Calendar" {
				calendarID = s.Id
			}
		}

		deletedEvent, err := calendarService.Events.Get(calendarID, meetingID.Hex()).Do()
		if err != nil {
			http.Error(w, "Could not find event in calendar"+err.Error(), http.StatusExpectationFailed)
			return
		}

		err = calendarService.Events.Delete(calendarID, meetingID.Hex()).Do()
		if err != nil {
			http.Error(w, "Could not delete event from calendar: "+err.Error(), http.StatusExpectationFailed)
			return
		}

		log.Printf("Deleted event %s", deletedEvent.Summary)
	}

	json.NewEncoder(w).Encode(updatedEvent)
}
