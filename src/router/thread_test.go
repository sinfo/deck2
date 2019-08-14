package router

import (
	"encoding/json"
	"log"
	"net/http"
	"testing"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	Thread = models.Thread{Entry: primitive.NewObjectID(), Meeting: nil, Kind: models.ThreadKindTo, Subscribers: []primitive.ObjectID{}}
)

func TestGetThread(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	ctd := &mongodb.CreateThreadData{
		Entry:       Thread.Entry,
		Meeting:     Thread.Meeting,
		Kind:        Thread.Kind,
		Subscribers: Thread.Subscribers,
	}

	createdThread, err := mongodb.Threads.CreateThread(*ctd)
	assert.NilError(t, err)

	var thread models.Thread

	res, err := executeRequest("GET", "/threads/"+createdThread.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&thread)

	assert.Equal(t, thread.ID, createdThread.ID)
}

func TestGetThreadNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/threads/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
