package mongodb

import (
	"context"
	"log"
	"time"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// NotificationsType contains database information on Notifications
type NotificationsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// GetNotification finds a notification with specified id.
func (n *NotificationsType) GetNotification(id primitive.ObjectID) (*models.Notification, error) {

	var notification models.Notification

	if err := n.Collection.FindOne(n.Context, bson.M{"_id": id}).Decode(&notification); err != nil {
		return nil, err
	}

	return &notification, nil
}

func (n *NotificationsType) Notify(data models.Notification) {

	var notification *models.Notification

	if err := data.Validate(); err != nil {
		log.Println("invalid notification: ", err.Error())
		return
	}

	signature := data.Hash()

	// check if there is already a notification with this signature
	if err := n.Collection.FindOne(n.Context, bson.M{"signature": signature}).Decode(&notification); err == nil {
		return
	}

	insertData := bson.M{
		"member":    data.Member,
		"kind":      data.Kind,
		"post":      data.Post,
		"speaker":   data.Speaker,
		"company":   data.Company,
		"meeting":   data.Meeting,
		"session":   data.Session,
		"signature": signature,
		"date":      time.Now().UTC(),
	}

	insertResult, err := n.Collection.InsertOne(n.Context, insertData)
	if err != nil {
		log.Println("unable to insert created notification: ", err.Error())
		return
	}

	notification, err = n.GetNotification(insertResult.InsertedID.(primitive.ObjectID))
	if err != nil {
		log.Println("unable to retrieve created notification: ", err.Error())
		return
	}
}

func (n *NotificationsType) GetMemberNotifications(memberID primitive.ObjectID) ([]*models.Notification, error) {

	var notifications = make([]*models.Notification, 0)

	filter := bson.M{
		"member": memberID,
	}

	cur, err := n.Collection.Find(n.Context, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(n.Context) {

		// create a value into which the single document can be decoded
		var notification models.Notification
		err := cur.Decode(&notification)
		if err != nil {
			return nil, err
		}

		notifications = append(notifications, &notification)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(n.Context)

	return notifications, nil
}

// GetMultipleNotifications gets notification by a list of IDs
func (n *NotificationsType) GetMultipleNotifications(ids []primitive.ObjectID) ([]*models.Notification, error) {

	var notifications = make([]*models.Notification, 0)

	filter := bson.M{
		"_id": bson.M{
			"$in": ids,
		},
	}

	cur, err := n.Collection.Find(n.Context, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(n.Context) {

		// create a value into which the single document can be decoded
		var notification models.Notification
		err := cur.Decode(&notification)
		if err != nil {
			return nil, err
		}

		notifications = append(notifications, &notification)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(n.Context)

	return notifications, nil
}
