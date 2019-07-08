package mongodb

import (
	"context"
	"errors"
	"fmt"
	"log"

	"github.com/globalsign/mgo/bson"
	"github.com/sinfo/deck2/models"
	"go.mongodb.org/mongo-driver/mongo"
)

type EventsCollection struct {
	Collection *mongo.Collection
	Context    context.Context
}

// Cached version of the latest event.
var currentEvent *models.Event

// GetCurrentEvent returns the latest event or an error.
// The error is only returned if there is no cached version of the
// latest event, and it is impossible to make a connection to the database, or
// when there are no events. In this last case, something is terribly wrong.
func (events *EventsCollection) GetCurrentEvent() (*models.Event, error) {

	// Return cached version.
	if currentEvent != nil {
		return currentEvent, nil
	}

	var event *models.Event

	// Query for all events.
	cur, err := events.Collection.Find(events.Context, bson.M{})

	if err != nil {
		return nil, err
	}

	// Find the latest event by ID.
	for cur.Next(events.Context) {
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

	cur.Close(events.Context)

	if event == nil {
		return nil, errors.New("no events found")
	}

	currentEvent = event

	return event, nil
}

// CreateEvent creates a new event. It just takes a name as argument, because the only information being
// created is de id and name. The id is incremented to the latest event.
// WARNING: the first event should be added to the database manually.
func (events *EventsCollection) CreateEvent(name string) (*models.Event, error) {
	var newEvent models.Event

	latestEvent, err := events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var c = bson.M{
		"_id":  latestEvent.ID + 1,
		"name": name,
	}

	insertResult, err := events.Collection.InsertOne(events.Context, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := events.Collection.FindOne(events.Context, bson.M{"_id": insertResult.InsertedID}).Decode(&newEvent); err != nil {
		fmt.Println("Error finding created event:", err)
		return nil, err
	}

	currentEvent = &newEvent

	return &newEvent, nil
}
