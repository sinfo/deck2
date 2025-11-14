package mongodb

import (
	"context"
	"time"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// LogsType contains database information on Logs
type LogsType struct {
	Collection *mongo.Collection
}

// InsertLog creates a new log entry
func (l *LogsType) InsertLog(actor *primitive.ObjectID, action string, resource string, resourceID *primitive.ObjectID, data map[string]interface{}) (*models.Log, error) {
	ctx = context.Background()

	insertData := bson.M{
		"action":   action,
		"resource": resource,
		"date":     time.Now().UTC(),
	}

	if actor != nil {
		insertData["actor"] = actor
	}

	if resourceID != nil {
		insertData["resourceId"] = resourceID
	}

	// If the caller included an "event" key inside data, extract it and store
	// it as a top-level field on the log document. This preserves backwards
	// compatibility while keeping event as a first-class field.
	if data != nil {
		// try extract event
		if evRaw, ok := data["event"]; ok {
			switch v := evRaw.(type) {
			case int:
				insertData["event"] = v
			case int32:
				insertData["event"] = int(v)
			case int64:
				insertData["event"] = int(v)
			case float64:
				insertData["event"] = int(v)
			default:
				// ignore unrecognized types
			}
			// remove the event from the data map to avoid duplication
			delete(data, "event")
		}
		if len(data) > 0 {
			insertData["data"] = data
		}
	}

	res, err := l.Collection.InsertOne(ctx, insertData)
	if err != nil {
		return nil, err
	}

	oid := res.InsertedID.(primitive.ObjectID)

	return l.GetLog(oid)
}

// GetLog finds a log by id
func (l *LogsType) GetLog(id primitive.ObjectID) (*models.Log, error) {
	ctx = context.Background()

	var logEntry models.Log

	if err := l.Collection.FindOne(ctx, bson.M{"_id": id}).Decode(&logEntry); err != nil {
		return nil, err
	}

	return &logEntry, nil
}

// ListLogs returns logs matching filter with pagination
func (l *LogsType) ListLogs(filter bson.M, limit int64, skip int64) ([]*models.Log, error) {
	ctx = context.Background()

	if filter == nil {
		filter = bson.M{}
	}

	findOptions := options.Find()
	if limit > 0 {
		findOptions.SetLimit(limit)
	}
	if skip > 0 {
		findOptions.SetSkip(skip)
	}
	// default sort by date desc
	findOptions.SetSort(bson.D{{Key: "date", Value: -1}})

	cur, err := l.Collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, err
	}

	var result []*models.Log

	for cur.Next(ctx) {
		var lg models.Log
		if err := cur.Decode(&lg); err != nil {
			cur.Close(ctx)
			return nil, err
		}
		result = append(result, &lg)
	}

	if err := cur.Err(); err != nil {
		cur.Close(ctx)
		return nil, err
	}

	cur.Close(ctx)

	return result, nil
}
