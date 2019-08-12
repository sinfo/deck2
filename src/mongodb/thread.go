package mongodb

import (
	"context"

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

// GetThread finds a thread based on id
func (t *ThreadsType) GetThread(id primitive.ObjectID) (*models.Thread, error){
	var thread models.Thread

	if err := t.Collection.FindOne(t.Context, bson.M{"_id": id}).Decode(&thread); err != nil{
		return nil, err
	}

	return &thread, nil
}
