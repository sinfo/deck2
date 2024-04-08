package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"time"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson"
)

//EventsType holds the mongodb collection
type EventsType struct {
	Collection *mongo.Collection
}

// Cached version of the current public event
var currentPublicEvent *models.EventPublic

//ResetCurrentPublicEvent resets current public event
func ResetCurrentPublicEvent() {
	currentPublicEvent = nil
}

// GetCurrentEvent returns the latest event or an error.
// The error is only returned if there is no cached version of the
// latest event, and it is impossible to make a connection to the database, or
// when there are no events. In this last case, something is terribly wrong.
func (e *EventsType) GetCurrentEvent() (*models.Event, error) {
	ctx := context.Background()

	var event *models.Event

	// Query for all events.
	cur, err := e.Collection.Find(ctx, bson.M{})

	if err != nil {
		return nil, err
	}

	// Find the latest event by ID.
	for cur.Next(ctx) {
		var e models.Event

		err := cur.Decode(&e)

		if err != nil {
			return nil, err
		}

		if event == nil || event.ID < e.ID {
			event = &e
		}

	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(ctx)

	if event == nil {
		return nil, errors.New("no events found")
	}

	return event, nil
}

func eventToPublic(event models.Event) *models.EventPublic {

	public := models.EventPublic{
		ID:     event.ID,
		Name:   event.Name,
		Begin:  event.Begin,
		End:    event.End,
		Themes: event.Themes,
	}

	return &public
}

//CreateEventData holds data needed to create an event
type CreateEventData struct {
	Name string `json:"name"`
}

// ParseBody fills the CreateEventData from a body
func (ced *CreateEventData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ced); err != nil {
		return err
	}

	if len(ced.Name) == 0 {
		return errors.New("invalid name")
	}

	return nil
}

// CreateEvent creates a new event. It just takes a name as argument, because the only information being
// created is de id and name. The id is incremented to the latest event.
// WARNING: the first event should be added to the database manually.
func (e *EventsType) CreateEvent(data CreateEventData) (*models.Event, error) {
	ctx := context.Background()

	latestEvent, err := e.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var c = bson.M{
		"_id":         latestEvent.ID + 1,
		"name":        data.Name,
		"themes":      make([]string, 0),
		"packages":    make([]models.EventPackages, 0),
		"items":       make([]primitive.ObjectID, 0),
		"meetings":    make([]primitive.ObjectID, 0),
		"sessions":    make([]primitive.ObjectID, 0),
		"teams":       make([]primitive.ObjectID, 0),
		"calendarUrl": "",
	}

	insertResult, err := e.Collection.InsertOne(ctx, c)

	if err != nil {
		log.Fatal(err)
	}

	var event models.Event

	if err := e.Collection.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&event); err != nil {
		log.Println("Error finding created event:", err)
		return nil, err
	}

	ResetCurrentPublicEvent()

	return &event, nil
}

// GetEventsOptions is the options to give to GetEvents.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetEventsOptions struct {
	Name   *string
	Before *time.Time
	After  *time.Time
	During *time.Time
}

// GetEvents gets an array of events using a filter.
func (e *EventsType) GetEvents(options GetEventsOptions) ([]*models.Event, error) {
	ctx := context.Background()

	var events = make([]*models.Event, 0)

	filter := bson.M{}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	if options.Before != nil {
		filter["begin"] = bson.M{"$lt": options.Before}
	}

	if options.After != nil {
		filter["begin"] = bson.M{"$gt": options.After}
	}

	if options.During != nil {
		filter["begin"] = bson.M{"$lte": options.During}
		filter["end"] = bson.M{"$gte": options.During}
	}

	cur, err := e.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {

		// create a value into which the single document can be decoded
		var e models.Event
		err := cur.Decode(&e)
		if err != nil {
			return nil, err
		}

		events = append(events, &e)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(ctx)

	return events, nil
}

// GetPublicEventsOptions is the options to give to GetEvents.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetPublicEventsOptions struct {
	Current    *bool
	PastEvents *bool
}

// GetPublicEvents gets an array of events using a filter, for public usage.
func (e *EventsType) GetPublicEvents(options GetPublicEventsOptions) ([]*models.EventPublic, error) {
	ctx := context.Background()

	var events = make([]*models.EventPublic, 0)

	filter := bson.M{}

	// nothing on the options, or past events and current event are both true, get all of them
	if (options.Current == nil && options.PastEvents == nil) ||
		(options.Current != nil && *options.Current && options.PastEvents != nil && *options.PastEvents) {

		cur, err := e.Collection.Find(ctx, filter)
		if err != nil {
			return nil, err
		}

		for cur.Next(ctx) {

			// create a value into which the single document can be decoded
			var e models.EventPublic
			err := cur.Decode(&e)
			if err != nil {
				return nil, err
			}

			events = append(events, &e)
		}

		if err := cur.Err(); err != nil {
			return nil, err
		}

		cur.Close(ctx)

		return events, nil
	}

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	// if current is true and past events not defined or false, then give current event
	if options.Current != nil && *options.Current && (options.PastEvents == nil || !*options.PastEvents) {

		e := eventToPublic(*currentEvent)
		events = append(events, e)

		return events, nil
	}

	// if past events is true and current not defined or false, then give past events
	if options.PastEvents != nil && *options.PastEvents && (options.Current == nil || !*options.Current) {
		cur, err := e.Collection.Find(ctx, filter)
		if err != nil {
			return nil, err
		}

		for cur.Next(ctx) {

			// create a value into which the single document can be decoded
			var e models.EventPublic
			err := cur.Decode(&e)
			if err != nil {
				return nil, err
			}

			if e.ID != currentEvent.ID {
				events = append(events, &e)
			}

		}

		if err := cur.Err(); err != nil {
			return nil, err
		}

		cur.Close(ctx)

		return events, nil
	}

	return events, nil
}

// GetEvent gets an event by its ID
func (e *EventsType) GetEvent(eventID int) (*models.Event, error) {
	ctx := context.Background()
	var event models.Event

	err := e.Collection.FindOne(ctx, bson.M{"_id": eventID}).Decode(&event)
	if err != nil {
		return nil, err
	}

	return &event, nil
}

// UpdateEventData holds data needed to update an event
type UpdateEventData struct {
	Name  string    `json:"name"`
	Begin time.Time `json:"begin"`
	End   time.Time `json:"end"`
}

// ParseBody fills the CreateEventData from a body
func (ued *UpdateEventData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ued); err != nil {
		return err
	}

	if len(ued.Name) == 0 {
		return errors.New("invalid name")
	}

	var now = time.Now()

	if now.After(ued.Begin) || now.After(ued.End) {
		return errors.New("invalid begin or end dates: must be in the future")
	}

	return nil
}

// UpdateEvent updates an event with ID eventID with the new data, using the UpdateEventData structure.
func (e *EventsType) UpdateEvent(eventID int, data UpdateEventData) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":  data.Name,
			"begin": data.Begin.UTC(),
			"end":   data.End.UTC(),
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event:", err)
		return nil, err
	}

	ResetCurrentPublicEvent()

	return &updatedEvent, nil
}

// DeleteEvent deletes an event.
func (e *EventsType) DeleteEvent(eventID int) (*models.Event, error) {
	ctx := context.Background()

	event, err := Events.GetEvent(eventID)
	if err != nil {
		return nil, err
	}

	deleteResult, err := Events.Collection.DeleteOne(ctx, bson.M{"_id": eventID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 event, deleted %v", deleteResult.DeletedCount)
	}

	ResetCurrentPublicEvent()

	return event, nil
}

// UpdateEventThemesData is the structure used for updating the event's themes.
type UpdateEventThemesData struct {

	// Themes for the event. It's a pointer for giving a nil value if the body to parse doesn't have
	// a themes key. Otherwise would give an empty array, because that's the starting value.
	Themes *[]string `json:"themes"`
}

// ParseBody fills the CreateEventData from a body
func (uetd *UpdateEventThemesData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(uetd); err != nil {
		return err
	}

	if uetd.Themes == nil {
		return errors.New("invalid body")
	}

	for _, t := range *uetd.Themes {
		if len(t) == 0 {
			return errors.New("empty theme")
		}
	}

	return nil
}

// UpdateThemes updates an event with ID eventID with new days' themes.
func (e *EventsType) UpdateThemes(eventID int, data UpdateEventThemesData) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$set": bson.M{
			"themes": data.Themes,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event's themes:", err)
		return nil, err
	}

	ResetCurrentPublicEvent()

	return &updatedEvent, nil
}

// UpdateTeams updates an event with ID eventID with new teams.
func (e *EventsType) UpdateTeams(eventID int, teams []primitive.ObjectID) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$set": bson.M{
			"teams": teams,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event's themes:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// AddEventPackageData is the structure used for adding a template to the event's packages.
type AddEventPackageData struct {
	Template   *primitive.ObjectID `json:"template"`
	PublicName *string             `json:"public_name"`
}

// ParseBody fills the AddEventPackageData from a body
func (aepd *AddEventPackageData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(aepd); err != nil {
		return err
	}

	if aepd.Template == nil {
		return errors.New("no package ID given")
	}

	if aepd.PublicName == nil {
		return errors.New("no public name given")
	}

	return nil
}

// AddPackage adds a template to an event's packages.
func (e *EventsType) AddPackage(eventID int, data AddEventPackageData) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"packages": bson.M{
				"template":    data.Template,
				"public_name": data.PublicName,
				"available":   true,
			},
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event's packages:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// AddSession adds a session to an event.
func (e *EventsType) AddSession(eventID int, sessionID primitive.ObjectID) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"sessions": sessionID,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event's sessions:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// RemovePackage removes a template from an event's packages.
func (e *EventsType) RemovePackage(eventID int, packageID primitive.ObjectID) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$pull": bson.M{
			"packages": bson.M{
				"template": packageID,
			},
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error removing package from event:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

//UpdateEventPackageData holds data needed to update an event package
type UpdateEventPackageData struct {
	PublicName *string `json:"public_name"`
	Available  *bool   `json:"available"`
}

// ParseBody fills the UpdateEventPackageData from a body
func (uepd *UpdateEventPackageData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(uepd); err != nil {
		return err
	}

	if uepd.PublicName == nil {
		return errors.New("no public name given")
	}

	if uepd.Available == nil {
		return errors.New("no available information given")
	}

	return nil
}

// UpdatePackage updates a template on an event.
func (e *EventsType) UpdatePackage(eventID int, packageID primitive.ObjectID, data UpdateEventPackageData) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$set": bson.M{
			"packages.$.available":   *data.Available,
			"packages.$.public_name": *data.PublicName,
		},
	}

	var filterQuery = bson.M{"_id": eventID, "packages.template": packageID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating template on event:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// AddEventItemData is the structure used for adding an item to an event.
type AddEventItemData struct {
	ItemID *primitive.ObjectID `json:"item"`
}

// ParseBody fills the AddEventItemData from a body
func (aeid *AddEventItemData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(aeid); err != nil {
		return err
	}

	if aeid.ItemID == nil {
		return errors.New("no item ID given")
	}

	return nil
}

// AddItem adds an item to an event.
func (e *EventsType) AddItem(eventID int, data AddEventItemData) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"items": *data.ItemID,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event's items:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// RemoveItem removes an item from an event.
func (e *EventsType) RemoveItem(eventID int, itemID primitive.ObjectID) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$pull": bson.M{
			"items": itemID,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error remove event's item:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// AddMeeting adds a meeting to an event.
func (e *EventsType) AddMeeting(eventID int, meetingID primitive.ObjectID) (*models.Event, error) {
	ctx := context.Background()
	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"meetings": meetingID,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event's meetings:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// RemoveMeeting removes a meeting from an event.
func (e *EventsType) RemoveMeeting(eventID int, meetingID primitive.ObjectID) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$pull": bson.M{
			"meetings": meetingID,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error remove event's item:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// RemoveTeam removes a team from an event
func (e *EventsType) RemoveTeam(eventID int, teamID primitive.ObjectID) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$pull": bson.M{
			"teams": teamID,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error remove event's item:", err)
		return nil, err
	}

	return &updatedEvent, nil
}

// Func that updates event calendar
func (e *EventsType) UpdateCalendar(eventID int, calendarUrl string) (*models.Event, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$set": bson.M{
			"calendarUrl": calendarUrl,
		},
	}

	var filterQuery = bson.M{"_id": eventID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedEvent models.Event

	if err := e.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("error updating event's calendar:", err)
		return nil, err
	}

	return &updatedEvent, nil
}
