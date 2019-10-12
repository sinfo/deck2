package mongodb

import (
	"context"
	"log"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson"
)

// ThreadsType contains important database information on Meetings
type ThreadsType struct {
	Collection *mongo.Collection
}

//CreateThreadData holds data needed to create a thread
type CreateThreadData struct {
	Entry   primitive.ObjectID
	Meeting *primitive.ObjectID
	Kind    models.ThreadKind
}

// CreateThread creates a new thread and saves it to the database
func (t *ThreadsType) CreateThread(data CreateThreadData) (*models.Thread, error) {
	ctx := context.Background()

	query := bson.M{
		"entry":    data.Entry,
		"comments": []primitive.ObjectID{},
		"status":   models.ThreadStatusPending,
		"kind":     data.Kind,
	}

	if data.Meeting != nil {
		query["meeting"] = *data.Meeting
	}

	insertResult, err := t.Collection.InsertOne(ctx, query)

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
	ctx := context.Background()
	var thread models.Thread

	err := t.Collection.FindOne(ctx, bson.M{"_id": threadID}).Decode(&thread)
	if err != nil {
		return nil, err
	}

	return &thread, nil
}

// DeleteThread deletes a thread by its ID.
func (t *ThreadsType) DeleteThread(threadID primitive.ObjectID) (*models.Thread, error) {
	ctx := context.Background()

	var thread models.Thread

	err := t.Collection.FindOneAndDelete(ctx, bson.M{"_id": threadID}).Decode(&thread)
	if err != nil {
		return nil, err
	}

	return &thread, nil
}

// AddCommentToThread adds a Post to a thread's comments.
func (t *ThreadsType) AddCommentToThread(threadID primitive.ObjectID, postID primitive.ObjectID) (*models.Thread, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"comments": postID,
		},
	}

	var filterQuery = bson.M{"_id": threadID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedThread models.Thread

	if err := t.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedThread); err != nil {
		log.Println("error updating thread:", err)
		return nil, err
	}

	return &updatedThread, nil
}

// RemoveCommentFromThread removes a comment Post from a thread
func (t *ThreadsType) RemoveCommentFromThread(threadID primitive.ObjectID, postID primitive.ObjectID) (*models.Thread, error) {
	ctx := context.Background()

	var updateQuery = bson.M{
		"$pull": bson.M{
			"comments": postID,
		},
	}

	var filterQuery = bson.M{"_id": threadID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedThread models.Thread

	if err := t.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedThread); err != nil {
		log.Println("error removing comment from thread:", err)
		return nil, err
	}

	return &updatedThread, nil
}
