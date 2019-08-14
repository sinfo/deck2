package mongodb

import (
	"context"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type ThreadsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type CreateThreadData struct {
	Entry       primitive.ObjectID
	Meeting     *primitive.ObjectID
	Kind        models.ThreadKind
	Subscribers []primitive.ObjectID
}

// CreateThread creates a new thread and saves it to the database
func (t *ThreadsType) CreateThread(data CreateThreadData) (*models.Thread, error) {

	query := bson.M{
		"entry":       data.Entry,
		"comments":    []primitive.ObjectID{},
		"status":      models.ThreadStatusPending,
		"kind":        data.Kind,
		"subscribers": data.Subscribers,
	}

	if data.Meeting != nil {
		query["meeting"] = *data.Meeting
	}

	insertResult, err := t.Collection.InsertOne(t.Context, query)

	if err != nil {
		return nil, err
	}

	newThread, err := t.GetThread(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created thread", err)
		return nil, err
	}

	return newThread, nil
}

// GetThread gets a thread by its ID.
func (t *ThreadsType) GetThread(threadID primitive.ObjectID) (*models.Thread, error) {
	var thread models.Thread

	err := t.Collection.FindOne(t.Context, bson.M{"_id": threadID}).Decode(&thread)
	if err != nil {
		return nil, err
	}

	return &thread, nil
}

// DeleteThread deletes a thread by its ID.
func (t *ThreadsType) DeleteThread(threadID primitive.ObjectID) (*models.Thread, error) {

	var thread models.Thread

	err := t.Collection.FindOneAndDelete(t.Context, bson.M{"_id": threadID}).Decode(&thread)
	if err != nil {
		return nil, err
	}

	return &thread, nil
}
