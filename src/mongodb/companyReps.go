package mongodb

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

// CompanyRepsType stores importat db information on contacts
type CompanyRepsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type GetCompanyRepOptions struct {
	Name	*string	`json:"name"`
}

// GetCompanyRep returns a CompanyRep based on id
func (c *CompanyRepsType) GetCompanyRep(id primitive.ObjectID) (*models.CompanyRep, error){

	var companyRep models.CompanyRep

	if err := c.Collection.FindOne(c.Context, bson.M{"_id": id}).Decode(&companyRep); err != nil{
		return nil, err
	}

	return &companyRep, nil
}

func (c *CompanyRepsType) GetCompanyReps(options GetCompanyRepOptions) ([]*models.CompanyRep, error){
	reps := make([]*models.CompanyRep, 0)

	filter := bson.M{}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	curr, err := c.Collection.Find(c.Context, filter)
	if err != nil{
		return nil, err
	}

	for curr.Next(c.Context){
		var rep models.CompanyRep

		if err := 	curr.Decode(&rep); err != nil{
			return nil, err
		}

		reps = append(reps,&rep)
	}

	curr.Close(c.Context)

	return reps, nil
}