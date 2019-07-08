package mongodb

import (
	"context"
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/sinfo/deck2/models"

	"github.com/globalsign/mgo/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type CompaniesCollection struct {
	Collection *mongo.Collection
	Context    context.Context
}

// CreateCompany creates a new company and saves it to the database
func (companies *CompaniesCollection) CreateCompany(name string, description string, site string) (*models.Company, error) {
	var newCompany models.Company

	var c = bson.M{
		"name":        name,
		"description": description,
		"site":        site,
	}

	insertResult, err := companies.Collection.InsertOne(ctx, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := companies.Collection.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&newCompany); err != nil {
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return &newCompany, nil
}

// AddParticipation adds a participation on the current event to the company with the indicated id.
func (companies *CompaniesCollection) AddParticipation(companyID primitive.ObjectID, memberID primitive.ObjectID, partner bool) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations": bson.M{
				"event":   currentEvent.ID,
				"member":  memberID,
				"partner": partner,
				"status":  models.Suggested,
			},
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := companies.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// TODO:
func (companies *CompaniesCollection) StepStatus(companyID primitive.ObjectID, eventID primitive.ObjectID, step int) (*models.Company, error) {
	//var updatedCompany models.Company

	//var updateQuery = bson.M{}

	//var filterQuery = bson.M{"_id": companyID}

	return nil, nil
}
