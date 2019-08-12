package mongodb

import (
	"context"
	"log"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

// ThreadsType contains important database information on Meetings
type ThreadsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// CreateThreadsData contains data needed to create a thread
type CreateThreadsData struct {
	Meeting		*primitive.ObjectID
	Kind 		models.ThreadKind
}

// GetThread finds a thread based on id
func (t *ThreadsType) GetThread(id primitive.ObjectID) (*models.Thread, error){
	var thread models.Thread

	if err := t.Collection.FindOne(t.Context, bson.M{"_id": id}).Decode(&thread); err != nil{
		return nil, err
	}

	return &thread, nil
}

// CreateThread creates a thread
func (t *ThreadsType) CreateThread( data CreateThreadsData) (*models.Thread, error){
	var thread models.Thread

	var c = bson.M{
		"kind": data.Kind,
	}

	if data.Meeting != nil{
		c["meeting"] = data.Meeting
	}

	insertResult, err := t.Collection.InsertOne(t.Context, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := t.Collection.FindOne(t.Context, bson.M{"_id": insertResult.InsertedID}).Decode(&thread); err != nil {
		log.Println("Error creating a meeting:", err)
		return nil, err
	}

	return &thread, nil
}
