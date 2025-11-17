package mongodb

import (
	"context"
	"log"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ItemCategoriesType holds the collection for item categories
type ItemCategoriesType struct {
	Collection *mongo.Collection
}

// Category model stored in DB
type categoryDoc struct {
	ID   primitive.ObjectID `bson:"_id"`
	Name string             `bson:"name"`
}

// GetCategories returns the list of categories with id and name
func (c *ItemCategoriesType) GetCategories() ([]map[string]string, error) {
	ctx := context.Background()
	cur, err := c.Collection.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	out := make([]map[string]string, 0)
	for cur.Next(ctx) {
		var d categoryDoc
		if err := cur.Decode(&d); err != nil {
			return nil, err
		}
		out = append(out, map[string]string{"id": d.ID.Hex(), "name": d.Name})
	}
	if err := cur.Err(); err != nil {
		return nil, err
	}
	return out, nil
}

// CreateCategory inserts a new category (name must be unique)
// returns the inserted document id
func (c *ItemCategoriesType) CreateCategory(name string) (primitive.ObjectID, error) {
	// we don't have a models type for categories; insert raw document
	ctx := context.Background()
	doc := bson.M{"name": name}
	insertResult, err := c.Collection.InsertOne(ctx, doc)
	if err != nil {
		return primitive.NilObjectID, err
	}
	id, ok := insertResult.InsertedID.(primitive.ObjectID)
	if !ok {
		return primitive.NilObjectID, nil
	}
	return id, nil
}

// UpdateCategory updates the name of a category by id
func (c *ItemCategoriesType) UpdateCategory(id primitive.ObjectID, name string) error {
	ctx := context.Background()
	filter := bson.M{"_id": id}
	update := bson.M{"$set": bson.M{"name": name}}
	res := c.Collection.FindOneAndUpdate(ctx, filter, update, options.FindOneAndUpdate().SetReturnDocument(options.After))
	if res.Err() != nil {
		return res.Err()
	}
	return nil
}

// DeleteCategory deletes a category by id
func (c *ItemCategoriesType) DeleteCategory(id primitive.ObjectID) error {
	ctx := context.Background()
	del, err := c.Collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return err
	}
	if del.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}
	return nil
}

// EnsureIndexes creates required indexes for categories
func (c *ItemCategoriesType) EnsureIndexes() error {
	ctx := context.Background()
	_, err := c.Collection.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys:    bson.D{{Key: "name", Value: 1}},
		Options: options.Index().SetUnique(true),
	})
	if err != nil {
		log.Println("Could not create index for itemCategories:", err)
		return err
	}
	return nil
}
