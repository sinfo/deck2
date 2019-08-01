package mongodb

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

type EventsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// Cached version of the latest event.
var currentEvent *models.Event

// GetCurrentEvent returns the latest event or an error.
// The error is only returned if there is no cached version of the
// latest event, and it is impossible to make a connection to the database, or
// when there are no events. In this last case, something is terribly wrong.
func (e *EventsType) GetCurrentEvent() (*models.Event, error) {

	// Return cached version.
	if currentEvent != nil {
		return currentEvent, nil
	}

	var event *models.Event

	// Query for all events.
	cur, err := e.Collection.Find(e.Context, bson.M{})

	if err != nil {
		return nil, err
	}

	// Find the latest event by ID.
	for cur.Next(e.Context) {
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

	cur.Close(e.Context)

	if event == nil {
		return nil, errors.New("no events found")
	}

	currentEvent = event

	return event, nil
}

// CreateEvent creates a new event. It just takes a name as argument, because the only information being
// created is de id and name. The id is incremented to the latest event.
// WARNING: the first event should be added to the database manually.
func (e *EventsType) CreateEvent(name string) (*models.Event, error) {
	var newEvent models.Event

	latestEvent, err := e.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var c = bson.M{
		"_id":      latestEvent.ID + 1,
		"name":     name,
		"themes":   make([]string, 0),
		"packages": make([]models.EventPackages, 0),
		"items":    make([]models.EventItems, 0),
		"meetings": make([]primitive.ObjectID, 0),
		"sessions": make([]primitive.ObjectID, 0),
	}

	insertResult, err := e.Collection.InsertOne(e.Context, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := e.Collection.FindOne(e.Context, bson.M{"_id": insertResult.InsertedID}).Decode(&newEvent); err != nil {
		log.Println("Error finding created event:", err)
		return nil, err
	}

	currentEvent = &newEvent

	return &newEvent, nil
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

	var events = make([]*models.Event, 0)

	filter := bson.M{}

	if options.Name != nil {
		filter["name"] = options.Name
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

	cur, err := e.Collection.Find(e.Context, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(e.Context) {

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

	cur.Close(e.Context)

	return events, nil
}

// GetEvent gets an event by its ID
func (e *EventsType) GetEvent(eventID int) (*models.Event, error) {
	var event models.Event

	err := e.Collection.FindOne(e.Context, bson.M{"_id": eventID}).Decode(&event)
	if err != nil {
		return nil, err
	}

	return &event, nil
}
