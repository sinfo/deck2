package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

type ItemsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// CreateItemData is the structure used on CreateItem
type CreateItemData struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Description string `json:"description"`
	Image       string `json:"img"`
	Price       int    `json:"price"`
	VAT         int    `json:"vat"`
}

// ParseBody fills the CreateItemData from a body
func (cid *CreateItemData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cid); err != nil {
		return err
	}

	if len(cid.Name) == 0 {
		return errors.New("invalid name")
	}

	if len(cid.Type) == 0 {
		return errors.New("invalid type")
	}

	if len(cid.Description) == 0 {
		return errors.New("invalid description")
	}

	if cid.Price < 0 {
		return errors.New("invalid price")
	}

	if cid.VAT < 0 || cid.VAT > 100 {
		return errors.New("invalid vat")
	}

	return nil
}

// CreateItem creates a new item.
func (i *ItemsType) CreateItem(data CreateItemData) (*models.Item, error) {

	var item models.Item

	var c = bson.M{
		"name":        data.Name,
		"type":        data.Type,
		"description": data.Description,
		"img":         data.Image,
		"price":       data.Price,
		"vat":         data.VAT,
	}

	insertResult, err := i.Collection.InsertOne(i.Context, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := i.Collection.FindOne(i.Context, bson.M{"_id": insertResult.InsertedID}).Decode(&item); err != nil {
		log.Println("Error finding created event:", err)
		return nil, err
	}

	return &item, nil
}

// GetItem gets an item by its ID
func (i *ItemsType) GetItem(itemID primitive.ObjectID) (*models.Item, error) {
	var item models.Item

	err := i.Collection.FindOne(i.Context, bson.M{"_id": itemID}).Decode(&item)
	if err != nil {
		return nil, err
	}

	return &item, nil
}
