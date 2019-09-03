package mongodb

import (
	"context"
	"log"
	"regexp"
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

var tagRegexCompiler, _ = regexp.Compile(`@[a-zA-Z0-9\.]+`)

func (n *NotificationsType) Notify(author primitive.ObjectID, subscribers []primitive.ObjectID, data CreateNotificationData) {

	// notify subscribers
	for _, subscriber := range subscribers {
		if subscriber == author {
			continue
		}

		n.NotifyMember(subscriber, data)
	}

	// notify coordination on the author's team
	event, err := Events.GetCurrentEvent()
	if err != nil {
		return
	}

	for _, teamID := range event.Teams {
		team, err := Teams.GetTeam(teamID)
		if err != nil || !team.HasMember(author) {
			continue
		}

		coordinators := team.GetMembersByRole(models.RoleCoordinator)

		for _, coordinator := range coordinators {
			if coordinator.Member == author {
				continue
			}

			n.NotifyMember(coordinator.Member, data)
		}
	}

	// notified tagged member
	var post *models.Post

	if data.Thread != nil && data.Post == nil {
		thread, err := Threads.GetThread(*data.Thread)
		if err != nil {
			return
		}

		post, err = Posts.GetPost(thread.Entry)
		if err != nil {
			return
		}
	} else if data.Post != nil {
		post, err = Posts.GetPost(*data.Post)
		if err != nil {
			return
		}
	}

	if post == nil {
		return
	}

	for _, tag := range tagRegexCompiler.FindAll([]byte(post.Text), -1) {
		if taggedMember, err := Members.GetMemberBySinfoID(string(tag)[1:]); err == nil {
			data.Kind = models.NotificationKindTagged
			data.Post = &post.ID
			n.NotifyMember(taggedMember.ID, data)
		}
	}
}

type CreateNotificationData struct {
	Kind    models.NotificationKind
	Post    *primitive.ObjectID
	Thread  *primitive.ObjectID
	Speaker *primitive.ObjectID
	Company *primitive.ObjectID
	Meeting *primitive.ObjectID
	Session *primitive.ObjectID
}

func (n *NotificationsType) NotifyMember(memberID primitive.ObjectID, data CreateNotificationData) {

	notification := &models.Notification{
		Kind:    data.Kind,
		Member:  memberID,
		Post:    data.Post,
		Thread:  data.Thread,
		Speaker: data.Speaker,
		Company: data.Company,
		Meeting: data.Meeting,
		Session: data.Session,
	}

	if err := notification.Validate(); err != nil {
		log.Println("invalid notification: ", err.Error())
		return
	}

	signature := notification.Hash()

	// check if there is already a notification with this signature
	if err := n.Collection.FindOne(n.Context, bson.M{"signature": signature}).Decode(notification); err == nil {
		return
	}

	insertData := bson.M{
		"member":    memberID,
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

// GetNotification finds a notification with specified id.
func (n *NotificationsType) GetNotification(id primitive.ObjectID) (*models.Notification, error) {

	var notification models.Notification

	if err := n.Collection.FindOne(n.Context, bson.M{"_id": id}).Decode(&notification); err != nil {
		return nil, err
	}

	return &notification, nil
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

// DeleteNotification deletes a notification by its ID.
func (n *NotificationsType) DeleteNotification(notificationID primitive.ObjectID) (*models.Notification, error) {

	var notification models.Notification

	err := n.Collection.FindOneAndDelete(n.Context, bson.M{"_id": notificationID}).Decode(&notification)
	if err != nil {
		return nil, err
	}

	return &notification, nil
}
