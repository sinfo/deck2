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

//FlightInfoType holds the mongodb collection
type FlightInfoType struct {
	Collection *mongo.Collection
}

//CreateFlightInfoData holds data needed to create a flightInfo
type CreateFlightInfoData struct {
	Inbound  *time.Time `json:"inbound"`
	Outbound *time.Time `json:"outbound"`
	From     *string    `json:"from"`
	To       *string    `json:"to"`
	Link     string     `json:"link"`
	Bought   *bool      `json:"bought"`
	Cost     *int       `json:"cost"`
	Notes    *string    `json:"notes"`
}

// ParseBody fills the CreateFlightInfo from a body
func (cfid *CreateFlightInfoData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cfid); err != nil {
		return err
	}

	if cfid.Inbound == nil {
		return errors.New("invalid inbound")
	}

	if cfid.Outbound == nil {
		return errors.New("invalid outbound")
	}

	if cfid.Inbound.Before(*cfid.Outbound) {
		return errors.New("inbound must be after outbound")
	}

	if cfid.From == nil {
		return errors.New("invalid from")
	}

	if cfid.To == nil {
		return errors.New("invalid to")
	}

	if cfid.Bought == nil {
		return errors.New("invalid bought")
	}

	if cfid.Cost == nil || *cfid.Cost < 0 {
		return errors.New("invalid cost")
	}

	if cfid.Notes == nil {
		return errors.New("invalid notes")
	}

	return nil
}

// CreateFlightInfo creates a new FlightInfo.
func (f *FlightInfoType) CreateFlightInfo(data CreateFlightInfoData) (*models.FlightInfo, error) {
	ctx := context.Background()

	var createdFlightInfo models.FlightInfo

	var c = bson.M{
		"inbound":  data.Inbound.UTC(),
		"outbound": data.Outbound.UTC(),
		"from":     data.From,
		"to":       data.To,
		"link":     data.Link,
		"bought":   data.Bought,
		"cost":     data.Cost,
		"notes":    data.Notes,
	}

	insertResult, err := f.Collection.InsertOne(ctx, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := f.Collection.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&createdFlightInfo); err != nil {
		log.Println("Error finding created flightInfo:", err)
		return nil, err
	}

	return &createdFlightInfo, nil
}

// DeleteFlightInfo deletes a flight info by its ID
func (f *FlightInfoType) DeleteFlightInfo(flightInfoID primitive.ObjectID) (*models.FlightInfo, error) {
	ctx := context.Background()

	flightInfo, err := FlightInfo.GetFlightInfo(flightInfoID)
	if err != nil {
		return nil, err
	}

	deleteResult, err := FlightInfo.Collection.DeleteOne(ctx, bson.M{"_id": flightInfoID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 flight info, deleted %v", deleteResult.DeletedCount)
	}

	return flightInfo, nil
}

// GetFlightInfo gets a flight info by its ID
func (f *FlightInfoType) GetFlightInfo(flightInfoID primitive.ObjectID) (*models.FlightInfo, error) {
	ctx := context.Background()

	var flightInfo models.FlightInfo

	err := f.Collection.FindOne(ctx, bson.M{"_id": flightInfoID}).Decode(&flightInfo)
	if err != nil {
		return nil, err
	}

	return &flightInfo, nil
}

// UpdateFlightInfo updates a new FlightInfo.
func (f *FlightInfoType) UpdateFlightInfo(flightInfoID primitive.ObjectID, data CreateFlightInfoData) (*models.FlightInfo, error) {
	ctx := context.Background()

	var flightInfo models.FlightInfo

	var updateQuery = bson.M{
		"$set": bson.M{
			"inbound":  data.Inbound.UTC(),
			"outbound": data.Outbound.UTC(),
			"from":     data.From,
			"to":       data.To,
			"link":     data.Link,
			"bought":   data.Bought,
			"cost":     data.Cost,
			"notes":    data.Notes,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := f.Collection.FindOneAndUpdate(ctx, bson.M{"_id": flightInfoID}, updateQuery, optionsQuery).Decode(&flightInfo); err != nil {
		return nil, err
	}

	return &flightInfo, nil
}
