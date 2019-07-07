package mongodb

import (
	"errors"
	"fmt"
	"log"

	"github.com/globalsign/mgo/bson"
	"github.com/sinfo/deck2/models"
	"go.mongodb.org/mongo-driver/mongo"
)

// MongoDB collection of events. Initialized on setup.go.
var events *mongo.Collection

// Cached version of the latest event.
var currentEvent *models.Event

// GetCurrentEvent returns the latest event or an error.
// The error is only returned if there is no cached version of the
// latest event, and it is impossible to make a connection to the database, or
// when there are no events. In this last case, something is terribly wrong.
func GetCurrentEvent() (*models.Event, error) {

	// Return cached version.
	if currentEvent != nil {
		return currentEvent, nil
	}

	var event *models.Event

	// Query for all events.
	cur, err := events.Find(ctx, bson.M{})

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

	currentEvent = event

	return event, nil
}

// CreateEvent creates a new event. It just takes a name as argument, because the only information being
// created is de id and name. The id is incremented to the latest event.
// WARNING: the first event should be added to the database manually.
func CreateEvent(name string) (*models.Event, error) {
	var newEvent models.Event

	latestEvent, err := GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var c = bson.M{
		"_id":  latestEvent.ID + 1,
		"name": name,
	}

	insertResult, err := events.InsertOne(ctx, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := events.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&newEvent); err != nil {
		fmt.Println("Error finding created event:", err)
		return nil, err
	}

	return &newEvent, nil
}
