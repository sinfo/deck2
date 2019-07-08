package mongodb

import (
	"context"
	"errors"
	"fmt"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/sinfo/deck2/models"

	"github.com/globalsign/mgo/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type CompaniesType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type CreateCompanyData struct {
	Name        string
	Description string
	Site        string
}

// CreateCompany creates a new company and saves it to the database
func (c *CompaniesType) CreateCompany(data CreateCompanyData) (*models.Company, error) {

	insertResult, err := c.Collection.InsertOne(c.Context, bson.M{
		"name":        data.Name,
		"description": data.Description,
		"site":        data.Site,
	})

	if err != nil {
		return nil, err
	}

	newCompany, err := c.GetCompany(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return newCompany, nil
}

// GetCompany gets a company by its ID.
func (c *CompaniesType) GetCompany(companyID primitive.ObjectID) (*models.Company, error) {
	var company models.Company

	err := c.Collection.FindOne(c.Context, bson.M{"_id": companyID}).Decode(&company)
	if err != nil {
		return nil, err
	}

	return &company, nil
}

type AddParticipationData struct {
	MemberID primitive.ObjectID
	Partner  bool
}

// AddParticipation adds a participation on the current event to the company with the indicated id.
func (c *CompaniesType) AddParticipation(companyID primitive.ObjectID, data AddParticipationData) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations": bson.M{
				"event":   currentEvent.ID,
				"member":  data.MemberID,
				"partner": data.Partner,
				"status":  models.Suggested,
			},
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// StepStatus advances the status of a company's participation in the current event,
// according to the given step (see models.Company).
func (c *CompaniesType) StepStatus(companyID primitive.ObjectID, eventID primitive.ObjectID, step int) (*models.Company, error) {

	var updatedCompany models.Company

	company, err := c.GetCompany(companyID)
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

		if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
			fmt.Println("Error updating company's status:", err)
			return nil, err
		}

		return &updatedCompany, nil
	}

	return nil, errors.New("company without participation on the current event")
}

type UpdateCompanyData struct {
	Name        string
	Description string
	Site        string
	BillingInfo models.CompanyBillingInfo
}

func (c *CompaniesType) UpdateCompany(companyID primitive.ObjectID, data UpdateCompanyData) (*models.Company, error) {

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":                data.Name,
			"description":         data.Description,
			"site":                data.Site,
			"billingInfo.name":    data.BillingInfo.Name,
			"billingInfo.address": data.BillingInfo.Address,
			"billingInfo.tin":     data.BillingInfo.TIN,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		fmt.Println("error updating company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

func (c *CompaniesType) DeleteCompany(companyID primitive.ObjectID) (*models.Company, error) {

	company, err := Companies.GetCompany(companyID)
	if err != nil {
		return nil, err
	}

	deleteResult, err := Companies.Collection.DeleteOne(Companies.Context, bson.M{"_id": companyID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 company, deleted %v", deleteResult.DeletedCount)
	}

	return company, nil
}
