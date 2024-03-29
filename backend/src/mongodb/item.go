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
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

//ItemsType holds a mongodb collection
type ItemsType struct {
	Collection *mongo.Collection
}

// CreateItemData is the structure used on CreateItem
type CreateItemData struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Description string `json:"description"`
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
	ctx = context.Background()

	var item models.Item

	var c = bson.M{
		"name":        data.Name,
		"type":        data.Type,
		"description": data.Description,
		"price":       data.Price,
		"vat":         data.VAT,
	}

	insertResult, err := i.Collection.InsertOne(ctx, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := i.Collection.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&item); err != nil {
		log.Println("Error finding created event:", err)
		return nil, err
	}

	return &item, nil
}

// GetItem gets an item by its ID
func (i *ItemsType) GetItem(itemID primitive.ObjectID) (*models.Item, error) {
	ctx = context.Background()
	var item models.Item

	err := i.Collection.FindOne(ctx, bson.M{"_id": itemID}).Decode(&item)
	if err != nil {
		return nil, err
	}

	return &item, nil
}

// UpdateItemData is the structure used in UpdateItem
type UpdateItemData struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Description string `json:"description"`
	Price       int    `json:"price"`
	VAT         int    `json:"vat"`
}

// ParseBody fills the CreateItemData from a body
func (uid *UpdateItemData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(uid); err != nil {
		return err
	}

	if len(uid.Name) == 0 {
		return errors.New("invalid name")
	}

	if len(uid.Type) == 0 {
		return errors.New("invalid type")
	}

	if len(uid.Description) == 0 {
		return errors.New("invalid description")
	}

	if uid.Price < 0 {
		return errors.New("invalid price")
	}

	if uid.VAT < 0 || uid.VAT > 100 {
		return errors.New("invalid vat")
	}

	return nil
}

// UpdateItem updates an item by its ID
func (i *ItemsType) UpdateItem(itemID primitive.ObjectID, data UpdateItemData) (*models.Item, error) {
	ctx = context.Background()

	var item models.Item

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":        data.Name,
			"type":        data.Type,
			"description": data.Description,
			"price":       data.Price,
			"vat":         data.VAT,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := i.Collection.FindOneAndUpdate(ctx, bson.M{"_id": itemID}, updateQuery, optionsQuery).Decode(&item); err != nil {
		return nil, err
	}

	return &item, nil
}

// DeleteItem deletes an item by its ID
func (i *ItemsType) DeleteItem(itemID primitive.ObjectID) (*models.Item, error) {
	ctx = context.Background()

	var item models.Item

	err := i.Collection.FindOne(ctx, bson.M{"_id": itemID}).Decode(&item)
	if err != nil {
		return nil, err
	}

	deleteResult, err := Items.Collection.DeleteOne(ctx, bson.M{"_id": itemID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 item, deleted %v", deleteResult.DeletedCount)
	}

	return &item, nil
}

// GetItemsOptions is the options to give to GetItems.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetItemsOptions struct {
	Name *string
	Type *string
}

// GetItems gets an array of events using a filter.
func (i *ItemsType) GetItems(options GetItemsOptions) ([]*models.Item, error) {
	ctx = context.Background()

	var items = make([]*models.Item, 0)

	filter := bson.M{}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	if options.Type != nil {
		filter["type"] = options.Type
	}

	cur, err := i.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {

		// create a value into which the single document can be decoded
		var i models.Item
		err := cur.Decode(&i)
		if err != nil {
			return nil, err
		}

		items = append(items, &i)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(ctx)

	return items, nil
}

// UpdateItemImage updates an item's image
func (i *ItemsType) UpdateItemImage(itemID primitive.ObjectID, url string) (*models.Item, error) {
	ctx = context.Background()

	var item models.Item

	var updateQuery = bson.M{
		"$set": bson.M{
			"img": url,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := i.Collection.FindOneAndUpdate(ctx, bson.M{"_id": itemID}, updateQuery, optionsQuery).Decode(&item); err != nil {
		return nil, err
	}

	return &item, nil

}
