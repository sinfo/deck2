package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"testing"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"gotest.tools/assert"
)

var (
	Speaker = models.Speaker{Name: "some-name", Bio: "some-bio", Title: "some-title"}
)

func TestCreateSpeaker(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newSpeaker models.Speaker

	createSpeakerData := &mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	b, errMarshal := json.Marshal(createSpeakerData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newSpeaker)

	assert.Equal(t, newSpeaker.Name, Speaker.Name)
	assert.Equal(t, newSpeaker.Bio, Speaker.Bio)
	assert.Equal(t, newSpeaker.Title, Speaker.Title)
}

func TestCreateSpeakerInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	type InvalidPayload struct {
		Name string `json:"name"`
	}

	createSpeakerData := &InvalidPayload{
		Name: Speaker.Name,
	}

	b, errMarshal := json.Marshal(createSpeakerData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetSpeakers(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	var speakers []models.Speaker

	res, err := executeRequest("GET", "/speakers", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&speakers)

	assert.Equal(t, len(speakers) == 1, true)
	assert.Equal(t, speakers[0].ID, newSpeaker.ID)
}

func TestGetSpeaker(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	var speaker models.Speaker

	res, err := executeRequest("GET", "/speakers/"+newSpeaker.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&speaker)

	assert.Equal(t, speaker.ID, newSpeaker.ID)
}

func TestGetSpeakerNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/speakers/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
