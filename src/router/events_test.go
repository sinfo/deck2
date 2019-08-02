package router

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"testing"
	"time"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	TimeBefore = time.Now().Add(-time.Hour * 10)
	TimeNow    = time.Now()
	TimeAfter  = time.Now().Add(time.Hour * 10)
	Event1     = models.Event{ID: 1, Name: "SINFO1"}
	Event2     = models.Event{ID: 2, Name: "SINFO2", Begin: &TimeBefore, End: &TimeNow}
	Event3     = models.Event{ID: 3, Name: "SINFO3", Begin: &TimeNow, End: &TimeAfter}
)

func containsEvent(events []models.Event, event models.Event) bool {
	for _, s := range events {
		if s.ID == event.ID && s.Name == event.Name {
			return true
		}
	}

	return false
}

func TestGetEvents(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event

	res, err := executeRequest("GET", "/events", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), true)
	assert.Equal(t, containsEvent(events, Event2), true)
}

func TestGetEventsByName(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?name=" + url.QueryEscape(Event1.Name)

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), true)
	assert.Equal(t, containsEvent(events, Event2), false)
}

func TestGetEventsBeforeDate(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event2.ID, "name": Event2.Name, "begin": Event2.Begin, "end": Event2.End}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event3.ID, "name": Event3.Name, "begin": Event3.Begin, "end": Event3.End}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?before=" + url.QueryEscape(Event3.Begin.Format(time.RFC3339))

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), false)
	assert.Equal(t, containsEvent(events, Event2), true)
	assert.Equal(t, containsEvent(events, Event3), false)
}

func TestGetEventsAfterDate(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event2.ID, "name": Event2.Name, "begin": Event2.Begin, "end": Event2.End}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event3.ID, "name": Event3.Name, "begin": Event3.Begin, "end": Event3.End}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?after=" + url.QueryEscape(Event2.End.Format(time.RFC3339))

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), false)
	assert.Equal(t, containsEvent(events, Event2), false)
	assert.Equal(t, containsEvent(events, Event3), true)
}

func TestGetEventsDuringDate(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event2.ID, "name": Event2.Name, "begin": Event2.Begin, "end": Event2.End}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event3.ID, "name": Event3.Name, "begin": Event3.Begin, "end": Event3.End}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?during=" + url.QueryEscape(Event3.Begin.Add(time.Hour).Format(time.RFC3339))

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), false)
	assert.Equal(t, containsEvent(events, Event2), false)
	assert.Equal(t, containsEvent(events, Event3), true)
}

func TestGetEventsBadQuery(t *testing.T) {

	var badQuery1 = "?before=wrong"
	var badQuery2 = "?after=wrong"
	var badQuery3 = "?during=wrong"

	res1, err1 := executeRequest("GET", "/events"+badQuery1, nil)
	res2, err2 := executeRequest("GET", "/events"+badQuery2, nil)
	res3, err3 := executeRequest("GET", "/events"+badQuery3, nil)
	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.NilError(t, err3)

	assert.Equal(t, res1.Code, http.StatusBadRequest)
	assert.Equal(t, res2.Code, http.StatusBadRequest)
	assert.Equal(t, res3.Code, http.StatusBadRequest)
}

func TestGetEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var event1, event2 models.Event

	res1, err1 := executeRequest("GET", fmt.Sprintf("/events/%v", Event1.ID), nil)
	res2, err2 := executeRequest("GET", fmt.Sprintf("/events/%v", Event2.ID), nil)
	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.Equal(t, res1.Code, http.StatusOK)
	assert.Equal(t, res2.Code, http.StatusOK)

	json.NewDecoder(res1.Body).Decode(&event1)
	json.NewDecoder(res2.Body).Decode(&event2)

	assert.Equal(t, event1.ID, Event1.ID)
	assert.Equal(t, event2.ID, Event2.ID)
}

func TestGetEventBadID(t *testing.T) {

	res, err := executeRequest("GET", "/events/bad_ID", nil)
	assert.NilError(t, err)

	assert.Equal(t, res.Code, http.StatusNotFound)
}
