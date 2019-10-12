package mongodb

import (
	"context"
	"log"
	"regexp"
	"time"

	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// NotificationsType contains database information on Notifications
type NotificationsType struct {
	Collection *mongo.Collection
}

var tagRegexCompiler, _ = regexp.Compile(`@[a-zA-Z0-9\.]+`)

//Notify creates a notification and adds it to every subscriber
func (n *NotificationsType) Notify(author primitive.ObjectID, data CreateNotificationData) {

	event, err := Events.GetCurrentEvent()
	if err != nil {
		return
	}

	if !config.Production {
		members, err := Teams.GetMembersByRole(models.RoleAdmin)
		if err != nil {
			log.Println("error fetching admins: " + err.Error())
		} else {
			for _, s := range members {
				n.NotifyMember(s, data)
			}
		}
	}

	// notify subscribers
	if data.Company != nil {
		company, err := Companies.GetCompany(*data.Company)
		if err != nil {
			return
		}

		for _, participation := range company.Participations {
			if participation.Event == event.ID {
				for _, subscriber := range participation.Subscribers {

					// notify authors only if not running on production mode
					if config.Production && subscriber == author {
						continue
					}

					n.NotifyMember(subscriber, data)
				}
				break
			}
		}
	}

	if data.Speaker != nil {
		speaker, err := Speakers.GetSpeaker(*data.Speaker)
		if err != nil {
			return
		}

		for _, participation := range speaker.Participations {
			if participation.Event == event.ID {
				for _, subscriber := range participation.Subscribers {

					// notify authors only if not running on production mode
					if config.Production && subscriber == author {
						continue
					}

					n.NotifyMember(subscriber, data)
				}
				break
			}
		}
	}

	// notify coordination on the author's team
	for _, teamID := range event.Teams {
		team, err := Teams.GetTeam(teamID)
		if err != nil || !team.HasMember(author) {
			continue
		}

		coordinators := team.GetMembersByRole(models.RoleCoordinator)

		for _, coordinator := range coordinators {

			// notify authors only if not running on production mode
			if config.Production && coordinator.Member == author {
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

//CreateNotificationData holds data needed to create a notification
type CreateNotificationData struct {
	Kind    models.NotificationKind
	Post    *primitive.ObjectID
	Thread  *primitive.ObjectID
	Speaker *primitive.ObjectID
	Company *primitive.ObjectID
	Meeting *primitive.ObjectID
	Session *primitive.ObjectID
}

//NotifyMember adds a notification to a member
func (n *NotificationsType) NotifyMember(memberID primitive.ObjectID, data CreateNotificationData) {
	ctx = context.Background()

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
	if err := n.Collection.FindOne(ctx, bson.M{"signature": signature}).Decode(notification); err == nil {
		return
	}

	insertData := bson.M{
		"member":    memberID,
		"kind":      data.Kind,
		"post":      data.Post,
		"thread":    data.Thread,
		"speaker":   data.Speaker,
		"company":   data.Company,
		"meeting":   data.Meeting,
		"session":   data.Session,
		"signature": signature,
		"date":      time.Now().UTC(),
	}

	insertResult, err := n.Collection.InsertOne(ctx, insertData)
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
	ctx = context.Background()

	var notification models.Notification

	if err := n.Collection.FindOne(ctx, bson.M{"_id": id}).Decode(&notification); err != nil {
		return nil, err
	}

	return &notification, nil
}

//GetMemberNotifications gets all notifications for a member
func (n *NotificationsType) GetMemberNotifications(memberID primitive.ObjectID) ([]*models.Notification, error) {
	ctx = context.Background()

	var notifications = make([]*models.Notification, 0)

	filter := bson.M{
		"member": memberID,
	}

	cur, err := n.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {

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

	cur.Close(ctx)

	return notifications, nil
}

// DeleteNotification deletes a notification by its ID.
func (n *NotificationsType) DeleteNotification(notificationID primitive.ObjectID) (*models.Notification, error) {
	ctx = context.Background()

	var notification models.Notification

	err := n.Collection.FindOneAndDelete(ctx, bson.M{"_id": notificationID}).Decode(&notification)
	if err != nil {
		return nil, err
	}

	return &notification, nil
}
