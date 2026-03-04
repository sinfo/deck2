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

// Notify creates a notification and adds it to every subscriber
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

	// Notify coordination teams: coordination logic lives in separate collection
	// Find coordination teams that include the author as a coordinated member
	// and notify those coordination teams' coordinators only.
	coordTeams, err := CoordinationTeams.GetCoordinationTeamsByMember(author)
	if err == nil {
		for _, coordTeam := range coordTeams {
			if coordTeam.Coordinator == nil {
				continue
			}
			// do not notify the author themselves in production
			if config.Production && coordTeam.Coordinator.Member == author {
				continue
			}
			n.NotifyMember(coordTeam.Coordinator.Member, data)
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

// CreateNotificationData holds data needed to create a notification
type CreateNotificationData struct {
	Kind    models.NotificationKind
	Post    *primitive.ObjectID
	Thread  *primitive.ObjectID
	Speaker *primitive.ObjectID
	Company *primitive.ObjectID
	Meeting *primitive.ObjectID
	Session *primitive.ObjectID
	// Optional human-friendly name of the target entity
	Name string
}

// NotifyMember adds a notification to a member
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
		Name:    data.Name,
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
		"name":      data.Name,
		"signature": signature,
		"date":      time.Now().UTC(),
	}

	insertResult, err := n.Collection.InsertOne(ctx, insertData)
	if err != nil {
		log.Println("unable to insert created notification: ", err.Error())
		return
	}

	_, err = n.GetNotification(insertResult.InsertedID.(primitive.ObjectID))
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

// GetMemberNotifications gets all notifications for a member
func (n *NotificationsType) GetMemberNotifications(memberID primitive.ObjectID) ([]map[string]interface{}, error) {
	ctx = context.Background()

	var notifications = make([]map[string]interface{}, 0)

	filter := bson.M{
		"member": memberID,
	}

	cur, err := n.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	type savedNotif struct {
		notifMap  map[string]interface{}
		speakerID *primitive.ObjectID
		companyID *primitive.ObjectID
	}

	var saved = make([]savedNotif, 0)
	speakerSet := make(map[primitive.ObjectID]struct{})
	companySet := make(map[primitive.ObjectID]struct{})

	for cur.Next(ctx) {

		// decode into models.Notification first
		var notification models.Notification

		err := cur.Decode(&notification)
		if err != nil {
			return nil, err
		}

		// build a JSON-friendly map for the response
		notifMap := map[string]interface{}{
			"id":        notification.ID.Hex(),
			"kind":      notification.Kind,
			"signature": notification.Signature,
			"member":    notification.Member.Hex(),
			"date":      notification.Date.Format(time.RFC3339),
			// include optional human-friendly name for deleted entities
			"name": notification.Name,
		}

		if notification.Post != nil {
			notifMap["post"] = notification.Post.Hex()
		}
		if notification.Thread != nil {
			notifMap["thread"] = notification.Thread.Hex()
		}
		if notification.Meeting != nil {
			notifMap["meeting"] = notification.Meeting.Hex()
		}
		if notification.Session != nil {
			notifMap["session"] = notification.Session.Hex()
		}

		var sID *primitive.ObjectID
		var cID *primitive.ObjectID

		if notification.Speaker != nil {
			sID = notification.Speaker
			// tentatively store the hex (fallback) until we embed
			notifMap["speaker"] = notification.Speaker.Hex()
			speakerSet[*sID] = struct{}{}
		}

		if notification.Company != nil {
			cID = notification.Company
			notifMap["company"] = notification.Company.Hex()
			companySet[*cID] = struct{}{}
		}

		saved = append(saved, savedNotif{notifMap: notifMap, speakerID: sID, companyID: cID})
	}

	// If we encountered speaker or company IDs, fetch them in batch and embed
	var speakersByID = make(map[primitive.ObjectID]*models.Speaker)
	var companiesByID = make(map[primitive.ObjectID]*models.Company)

	if len(speakerSet) > 0 {
		ids := make([]primitive.ObjectID, 0, len(speakerSet))
		for id := range speakerSet {
			ids = append(ids, id)
		}

		// batch find speakers
		spCur, err := Speakers.Collection.Find(ctx, bson.M{"_id": bson.M{"$in": ids}})
		if err == nil {
			for spCur.Next(ctx) {
				var sp models.Speaker
				if err := spCur.Decode(&sp); err == nil {
					speakersByID[sp.ID] = &sp
				}
			}
			spCur.Close(ctx)
		}
	}

	if len(companySet) > 0 {
		ids := make([]primitive.ObjectID, 0, len(companySet))
		for id := range companySet {
			ids = append(ids, id)
		}

		// batch find companies
		coCur, err := Companies.Collection.Find(ctx, bson.M{"_id": bson.M{"$in": ids}})
		if err == nil {
			for coCur.Next(ctx) {
				var co models.Company
				if err := coCur.Decode(&co); err == nil {
					companiesByID[co.ID] = &co
				}
			}
			coCur.Close(ctx)
		}
	}

	// build final notifications embedding the fetched objects when available
	for _, s := range saved {
		if s.speakerID != nil {
			if sp, ok := speakersByID[*s.speakerID]; ok {
				s.notifMap["speaker"] = sp
			}
		}
		if s.companyID != nil {
			if co, ok := companiesByID[*s.companyID]; ok {
				s.notifMap["company"] = co
			}
		}

		notifications = append(notifications, s.notifMap)
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

// DeleteAllMemberNotifications deletes all notifications for a member
func (n *NotificationsType) DeleteAllMemberNotifications(memberID primitive.ObjectID) (int64, error) {
	ctx = context.Background()

	filter := bson.M{
		"member": memberID,
	}

	deleteResult, err := n.Collection.DeleteMany(ctx, filter)
	if err != nil {
		return 0, err
	}

	return deleteResult.DeletedCount, nil
}
