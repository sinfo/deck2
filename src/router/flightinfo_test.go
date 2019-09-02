package router

import (
	"encoding/json"
	"log"
	"net/http"
	"testing"
	"time"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"gotest.tools/assert"
)

var (
	TimeFuture = TimeAfter.Add(time.Hour * 10)
	FlightInfo = models.FlightInfo{
		Inbound:  TimeFuture,
		Outbound: TimeAfter,
		From:     "Tashkent International Airport",
		To:       "Humberto Delgado Airport",
		Link:     "https://flightCompany.com/flight/1234567",
		Bought:   true,
		Cost:     23300,
		Notes:    "speaker's mom",
	}
)

func TestGetFlightInfo(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.FlightInfo.Collection.Drop(mongodb.FlightInfo.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	cfid := &mongodb.CreateFlightInfoData{
		Inbound:  &FlightInfo.Inbound,
		Outbound: &FlightInfo.Outbound,
		From:     &FlightInfo.From,
		To:       &FlightInfo.To,
		Link:     FlightInfo.Link,
		Bought:   &FlightInfo.Bought,
		Cost:     &FlightInfo.Cost,
		Notes:    &FlightInfo.Notes,
	}

	newFlightInfo, err := mongodb.FlightInfo.CreateFlightInfo(*cfid)
	assert.NilError(t, err)

	var flightInfo models.FlightInfo

	res, err := executeRequest("GET", "/flightInfo/"+newFlightInfo.ID.Hex(), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&flightInfo)

	assert.Equal(t, flightInfo.ID, newFlightInfo.ID)
}

func TestGetFlightInfoNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/flightInfo/"+primitive.NewObjectID().Hex(), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
