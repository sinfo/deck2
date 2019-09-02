package models

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type NotificationKind string

const (
	NotificationKindCreated NotificationKind = "CREATED"
	NotificationKindUpdated NotificationKind = "UPDATED"
	NotificationKindTagged  NotificationKind = "TAGGED"
	NotificationKindDeleted NotificationKind = "DELETED"
)

// Notification is created to warn a Member about a change to a certain entity
// (Post, Speaker, Company or Meeting). This will be added to the Member
// if he/she is on the entity's subscribers' list.
type Notification struct {

	// Notification's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Kind NotificationKind `json:"kind" bson:"kind"`

	// Post is an _id of Post (see models.Post).
	Post *primitive.ObjectID `json:"post,omitempty" bson:"post,omitempty"`

	// Speaker is an _id of Speaker (see models.Speaker).
	Speaker *primitive.ObjectID `json:"speaker,omitempty" bson:"speaker,omitempty"`

	// Company is an _id of Company (see models.Company).
	Company *primitive.ObjectID `json:"company,omitempty" bson:"company,omitempty"`

	// Meeting is an _id of Meeting (see models.Meeting).
	Meeting *primitive.ObjectID `json:"meeting,omitempty" bson:"meeting,omitempty"`

	// Session is an _id of Session (see models.Session).
	Session *primitive.ObjectID `json:"session,omitempty" bson:"session,omitempty"`

	Date time.Time `json:"date" bson:"date"`

	// Signature is used to verify if 2 notifications are equal
	Signature string `bson:"signature"`
}

func (n *Notification) Validate() error {

	var valid bool

	if n.Kind == NotificationKindTagged {
		if n.Post == nil {
			return errors.New("missing post")
		}
	} else if n.Kind == NotificationKindCreated ||
		n.Kind == NotificationKindUpdated ||
		n.Kind == NotificationKindDeleted {

		// at least one must exist
		valid = false
		valid = valid || n.Post != nil
		valid = valid || n.Speaker != nil
		valid = valid || n.Company != nil
		valid = valid || n.Meeting != nil
		valid = valid || n.Session != nil

		if !valid {
			return errors.New("missing created data")
		}
	}

	return nil
}

// Hash gets the signature of this notification, given that will be used to notifiy some user
// This will avoid multiple identical notifications to the same user
func (n *Notification) Hash(memberID primitive.ObjectID) string {

	digester := sha256.New()

	digester.Write([]byte(n.Kind))
	digester.Write([]byte(memberID.Hex()))

	if n.Post != nil {
		digester.Write([]byte(n.Post.Hex()))
	}

	if n.Speaker != nil {
		digester.Write([]byte(n.Post.Hex()))
	}

	if n.Company != nil {
		digester.Write([]byte(n.Post.Hex()))
	}

	if n.Meeting != nil {
		digester.Write([]byte(n.Post.Hex()))
	}

	if n.Session != nil {
		digester.Write([]byte(n.Post.Hex()))
	}

	return hex.EncodeToString(digester.Sum(nil))
}

func (n *Notification) Equals(other *Notification) bool {

	if n == nil || other == nil {
		return false
	}

	return n.Signature == other.Signature
}
