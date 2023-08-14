package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// TemplateType holds collection info
type TemplateType struct {
	Collection *mongo.Collection
}

// CreateTemplateData holds data needed to create a template
type TemplateData struct {
	Requirements *[]models.Requirement `json:"requirements"`
}

// ParseBody fills the CreateTemplateData from a body
func (ctd *TemplateData) ParseCreateBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ctd); err != nil {
		return err
	}

	if ctd.Requirements == nil {
		return errors.New("invalid name")
	}

	return nil
}

// ParseBody fills the CreateTemplateData from a body
func (ctd *TemplateData) ParseFillBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ctd); err != nil {
		return err
	}

	//TODO check body fields
	if ctd.Requirements == nil {
		return errors.New("invalid name")
	}

	return nil
}

//TODO still not in use, testing needed
// CreateTemplate creates a new template and saves it to the database
// func (t *TemplateType) CreateTemplate(data TemplateData, name string) (*models.Template, error) {
// 	ctx := context.Background()

// 	insertResult, err := t.Collection.InsertOne(ctx, bson.M{
// 		"name":         name,
// 		"requirements": data.Requirements,
// 	})

// 	if err != nil {
// 		return nil, err
// 	}

// 	newTemplate, err := t.GetTemplate(insertResult.InsertedID.(primitive.ObjectID))

// 	if err != nil {
// 		log.Println("Error finding created template", err)
// 		return nil, err
// 	}

// 	ResetCurrentPublicTemplates()

// 	return newTemplate, nil
// }

func (t *TemplateType) UpdateTemplateUrl(templateID primitive.ObjectID, url string) (*models.Template, error) {
	var updateQuery = bson.M{
		"$set": bson.M{
			"url": url,
		},
	}

	var filterQuery = bson.M{"_id": templateID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedTemplate models.Template

	if err := t.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedTemplate); err != nil {
		log.Println("error updating template:", err)
		return nil, err
	}

	return &updatedTemplate, nil
}

// GetTemplate gets a template by its ID.
func (t *TemplateType) GetTemplate(templateID primitive.ObjectID) (*models.Template, error) {

	ctx := context.Background()
	var template models.Template

	err := t.Collection.FindOne(ctx, bson.M{"_id": templateID}).Decode(&template)
	if err != nil {
		return nil, err
	}

	return &template, nil
}

// // UpdateTemplateData is the data used to update a template, using the method UpdateTemplate.
// type UpdateTemplateData struct {
// 	Name *string
// }

// // ParseBody fills the UpdateTemplateData from a body
// func (utd *UpdateTemplateData) ParseBody(body io.Reader) error {

// 	if err := json.NewDecoder(body).Decode(utd); err != nil {
// 		return err
// 	}

// 	return nil
// }

// GetTemplatesOptions is the options to give to GetTemplates.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetTemplatesOptions struct {
	EventID *int
	Name    *string
}

// GetTemplates gets all templates specified with a query
func (t *TemplateType) GetTemplates(tempOptions GetTemplatesOptions) ([]*models.Template, error) {
	var template = make([]*models.Template, 0)

	ctx := context.Background()

	filter := bson.M{}
	elemMatch := bson.M{}

	//findOptions := options.Find()

	if tempOptions.EventID != nil {
		elemMatch["event"] = tempOptions.EventID
	}

	if tempOptions.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *tempOptions.Name),
			"$options": "i",
		}
	}

	//var err error
	//var cur *mongo.Cursor

	//cur, err = t.Collection.Find(ctx, filter, findOptions)
	cur, err := t.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {

		// create a value into which the single document can be decoded
		var t models.Template
		err := cur.Decode(&t)
		if err != nil {
			return nil, err
		}

		template = append(template, &t)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(ctx)

	return template, nil
}
