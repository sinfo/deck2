package mongodb

import (
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/entities"

	"github.com/globalsign/mgo/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

var companies *mongo.Collection

// CreateCompany creates a new company and saves it to the database
func CreateCompany(name string, description string, site string) (*entities.Company, error) {
	var newCompany entities.Company

	var c = bson.M{
		"name":        name,
		"description": description,
		"site":        site,
	}

	insertResult, err := companies.InsertOne(ctx, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := companies.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&newCompany); err != nil {
		fmt.Errorf("Error finding created company: %s", err)
		return nil, err
	}

	return &newCompany, nil
}

// AddParticipation adds a participation on the current event to the company with the indicated id
func AddParticipation(id primitive.ObjectID, member string, partner bool) (*entities.Company, error) {

	var updatedCompany entities.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"member":  member,
			"partner": partner,
		},
	}

	var filterQuery = bson.M{"_id": id}

	if err := companies.FindOneAndUpdate(ctx, filterQuery, updateQuery).Decode(&updatedCompany); err != nil {
		fmt.Errorf("Error finding created company: %s", err)
		return nil, err
	}

	return &updatedCompany, nil
}
