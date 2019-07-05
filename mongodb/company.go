package mongodb

import (
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

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
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return &newCompany, nil
}

// AddParticipation adds a participation on the current event to the company with the indicated id
// TODO: add participation to the _current_ event
func AddParticipation(id primitive.ObjectID, member primitive.ObjectID, partner bool) (*entities.Company, error) {

	var updatedCompany entities.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations": bson.M{
				"member":  member,
				"partner": partner,
				"status":  "SUGGESTED",
			},
		},
	}

	var filterQuery = bson.M{"_id": id}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := companies.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		fmt.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}
