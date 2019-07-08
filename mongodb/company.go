package mongodb

import (
	"context"
	"errors"
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

	var c = bson.M{
		"name":        name,
		"description": description,
		"site":        site,
	}

	insertResult, err := companies.Collection.InsertOne(companies.Context, c)

	if err != nil {
		log.Fatal(err)
	}

	newCompany, err := companies.GetCompany(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return newCompany, nil
}

// GetCompany gets a company by its ID.
func (companies *CompaniesCollection) GetCompany(companyID primitive.ObjectID) (*models.Company, error) {
	var company models.Company

	err := companies.Collection.FindOne(companies.Context, bson.M{"_id": companyID}).Decode(&company)
	if err != nil {
		return nil, err
	}

	return &company, nil
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

	if err := companies.Collection.FindOneAndUpdate(companies.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// StepStatus advances the status of a company's participation in the current event,
// according to the given step (see models.Company).
func (companies *CompaniesCollection) StepStatus(companyID primitive.ObjectID, eventID primitive.ObjectID, step int) (*models.Company, error) {

	var updatedCompany models.Company

	company, err := companies.GetCompany(companyID)
	if err != nil {
		return nil, err
	}

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	for i, p := range company.Participations {
		if p.Event != currentEvent.ID {
			continue
		}

		err := company.Participations[i].Status.Next(step)

		if err != nil {
			return nil, err
		}

		var updateQuery = bson.M{
			"$set": bson.M{
				"participations.$.status": company.Participations[i].Status,
			},
		}

		var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

		var optionsQuery = options.FindOneAndUpdate()
		optionsQuery.SetReturnDocument(options.After)

		if err := companies.Collection.FindOneAndUpdate(companies.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
			fmt.Println("Error finding created company:", err)
			return nil, err
		}

		return &updatedCompany, nil
	}

	return nil, errors.New("company without participation on the current event")
}
