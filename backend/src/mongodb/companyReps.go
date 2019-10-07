package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson"
)

// CompanyRepsType stores importat db information on contacts
type CompanyRepsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// GetCompanyRepOptions is a filter for GetCompanyReps
type GetCompanyRepOptions struct {
	Name *string `json:"name"`
}

// CreateCompanyRepData contains data needed to create a rep
type CreateCompanyRepData struct {
	Name    *string            `json:"name" bson:"name"`
	Contact *CreateContactData `json:"contact" bson:"contact"`
}

// ParseBody fills a CreateCompanyRepData
func (ccrp *CreateCompanyRepData) ParseBody(body io.Reader) error {
	json.NewDecoder(body).Decode(ccrp)

	if ccrp.Name == nil {
		return errors.New("Invalid name")
	}
	return nil
}

// GetCompanyRep returns a CompanyRep based on id
func (c *CompanyRepsType) GetCompanyRep(id primitive.ObjectID) (*models.CompanyRep, error) {

	var companyRep models.CompanyRep

	if err := c.Collection.FindOne(c.Context, bson.M{"_id": id}).Decode(&companyRep); err != nil {
		return nil, err
	}

	return &companyRep, nil
}

//GetCompanyReps gets all reps based on a filter
func (c *CompanyRepsType) GetCompanyReps(options GetCompanyRepOptions) ([]*models.CompanyRep, error) {
	reps := make([]*models.CompanyRep, 0)

	filter := bson.M{}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	curr, err := c.Collection.Find(c.Context, filter)
	if err != nil {
		return nil, err
	}

	for curr.Next(c.Context) {
		var rep models.CompanyRep

		if err := curr.Decode(&rep); err != nil {
			return nil, err
		}

		reps = append(reps, &rep)
	}

	curr.Close(c.Context)

	return reps, nil
}

//CreateCompanyRep creates a company rep
func (c *CompanyRepsType) CreateCompanyRep(data CreateCompanyRepData) (*models.CompanyRep, error) {

	dataQuery := bson.M{"name": data.Name}

	if data.Contact != nil {
		contact, err := Contacts.CreateContact(*data.Contact)
		if err != nil {
			return nil, err
		}

		dataQuery["contact"] = contact.ID
	}

	insertResult, err := c.Collection.InsertOne(c.Context, dataQuery)

	if err != nil {
		return nil, err
	}

	newRep, err := c.GetCompanyRep(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created companyRep", err)
		return nil, err
	}

	return newRep, nil
}

// UpdateCompanyRep creates a contact and adds it to a companyRep
func (c *CompanyRepsType) UpdateCompanyRep(id primitive.ObjectID, data CreateCompanyRepData) (*models.CompanyRep, error) {

	var updateQuery = bson.M{
		"$set": bson.M{
			"name": data.Name,
		},
	}

	if data.Contact != nil {
		contact, err := Contacts.CreateContact(*data.Contact)
		if err != nil {
			return nil, err
		}

		updateQuery["$Set.contact"] = contact.ID
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var filterQuery = bson.M{"_id": id}

	var updatedRep models.CompanyRep
	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedRep); err != nil {
		return nil, err
	}

	return &updatedRep, nil
}

// DeleteCompanyRep deletes a companyRep
func (c *CompanyRepsType) DeleteCompanyRep(id primitive.ObjectID) (*models.CompanyRep, error) {

	rep, err := c.GetCompanyRep(id)
	if err != nil {
		return nil, err
	}

	deleteResult, err := c.Collection.DeleteOne(c.Context, bson.M{"_id": id})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 rep, deleted %v", deleteResult.DeletedCount)
	}

	return rep, nil
}
