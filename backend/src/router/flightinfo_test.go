package router

import (
	"bytes"
	"context"
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
	TimeFuture      = TimeAfter.Add(time.Hour * 10)
	TimeAfterFuture = TimeFuture.Add(time.Hour * 10)
	FlightInfo      = models.FlightInfo{
		Inbound:  TimeFuture,
		Outbound: TimeAfter,
		From:     "Tashkent International Airport",
		To:       "Humberto Delgado Airport",
		Link:     "https://flightCompany.com/flight/1234567",
		Bought:   true,
		Cost:     23300,
		Notes:    "speaker's mom",
	}
	FlightInfo2 = models.FlightInfo{
		Inbound:  TimeAfterFuture,
		Outbound: TimeFuture,
		From:     "Another airport",
		To:       "Yet another airport",
		Link:     "https://flightCompany.com/flight/7654321",
		Bought:   false,
		Cost:     12000,
		Notes:    "speaker's dad",
	}
)

func TestGetFlightInfo(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.FlightInfo.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/flightInfo/"+primitive.NewObjectID().Hex(), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdateFlightInfo(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.FlightInfo.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	ufid := &mongodb.CreateFlightInfoData{
		Inbound:  &FlightInfo2.Inbound,
		Outbound: &FlightInfo2.Outbound,
		From:     &FlightInfo2.From,
		To:       &FlightInfo2.To,
		Link:     FlightInfo2.Link,
		Bought:   &FlightInfo2.Bought,
		Cost:     &FlightInfo2.Cost,
		Notes:    &FlightInfo2.Notes,
	}

	b, errMarshal := json.Marshal(ufid)
	assert.NilError(t, errMarshal)

	var flightInfo models.FlightInfo

	res, err := executeRequest("PUT", "/flightInfo/"+newFlightInfo.ID.Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&flightInfo)

	assert.Equal(t, flightInfo.ID, newFlightInfo.ID)
	assert.Equal(t, flightInfo.Inbound.Sub(*ufid.Inbound).Seconds() < 10e-3, true)   // millisecond precision
	assert.Equal(t, flightInfo.Outbound.Sub(*ufid.Outbound).Seconds() < 10e-3, true) // millisecond precision
	assert.Equal(t, flightInfo.From, *ufid.From)
	assert.Equal(t, flightInfo.To, *ufid.To)
	assert.Equal(t, flightInfo.Link, ufid.Link)
	assert.Equal(t, flightInfo.Bought, *ufid.Bought)
	assert.Equal(t, flightInfo.Cost, *ufid.Cost)
	assert.Equal(t, flightInfo.Notes, *ufid.Notes)
}

func TestUpdateFlightInfoNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	ufid := &mongodb.CreateFlightInfoData{
		Inbound:  &FlightInfo2.Inbound,
		Outbound: &FlightInfo2.Outbound,
		From:     &FlightInfo2.From,
		To:       &FlightInfo2.To,
		Link:     FlightInfo2.Link,
		Bought:   &FlightInfo2.Bought,
		Cost:     &FlightInfo2.Cost,
		Notes:    &FlightInfo2.Notes,
	}

	b, errMarshal := json.Marshal(ufid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("GET", "/flightInfo/"+primitive.NewObjectID().Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
