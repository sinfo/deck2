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
	NotificationKindDeleted NotificationKind = "DELETED"

	NotificationKindUpdatedPrivateImage   NotificationKind = "UPDATED_PRIVATE_IMAGE"
	NotificationKindUpdatedPublicImage    NotificationKind = "UPDATED_PUBLIC_IMAGE"
	NotificationKindUploadedMeetingMinute NotificationKind = "UPDLOADED_MEETING_MINUTE"

	// Speaker's company image
	NotificationKindUpdatedCompanyImage NotificationKind = "UPDATED_COMPANY_IMAGE"

	NotificationKindCreatedParticipation NotificationKind = "CREATED_PARTICIPATION"
	NotificationKindUpdatedParticipation NotificationKind = "UPDATED_PARTICIPATION"
	NotificationKindDeletedParticipation NotificationKind = "DELETED_PARTICIPATION"

	NotificationKindCreatedParticipationPackage NotificationKind = "CREATED_PARTICIPATION_PACKAGE"
	NotificationKindUpdatedParticipationPackage NotificationKind = "UPDATED_PARTICIPATION_PACKAGE"
	NotificationKindDeletedParticipationPackage NotificationKind = "DELETED_PARTICIPATION_PACKAGE"

	NotificationKindUpdatedParticipationStatus NotificationKind = "UPDATED_PARTICIPATION_STATUS"

	NotificationKindTagged NotificationKind = "TAGGED"
)

// Notification is created to warn a Member about a change to a certain entity
// (Post, Speaker, Company or Meeting). This will be added to the Member
// if he/she is on the entity's subscribers' list.
type Notification struct {

	// Notification's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Kind NotificationKind `json:"kind" bson:"kind"`

	// Member to be notified
	Member primitive.ObjectID `json:"member" bson:"member"`

	// Post is an _id of Post (see models.Post).
	Post *primitive.ObjectID `json:"post,omitempty" bson:"post"`

	// Thread is an _id of Thread (see models.Thread).
	Thread *primitive.ObjectID `json:"thread,omitempty" bson:"thread"`

	// Speaker is an _id of Speaker (see models.Speaker).
	Speaker *primitive.ObjectID `json:"speaker,omitempty" bson:"speaker"`

	// Company is an _id of Company (see models.Company).
	Company *primitive.ObjectID `json:"company,omitempty" bson:"company"`

	// Meeting is an _id of Meeting (see models.Meeting).
	Meeting *primitive.ObjectID `json:"meeting,omitempty" bson:"meeting"`

	// Session is an _id of Session (see models.Session).
	Session *primitive.ObjectID `json:"session,omitempty" bson:"session"`

	Date time.Time `json:"date" bson:"date"`

	// Signature is used to verify if 2 notifications are equal
	Signature string `json:"signature" bson:"signature"`
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
		valid = valid || n.Thread != nil
		valid = valid || n.Speaker != nil
		valid = valid || n.Company != nil
		valid = valid || n.Meeting != nil
		valid = valid || n.Session != nil

		if !valid {
			return errors.New("missing data")
		}
	} else if n.Kind == NotificationKindUpdatedPrivateImage ||
		n.Kind == NotificationKindUpdatedPublicImage ||
		n.Kind == NotificationKindCreatedParticipation ||
		n.Kind == NotificationKindUpdatedParticipation ||
		n.Kind == NotificationKindDeletedParticipation ||
		n.Kind == NotificationKindCreatedParticipationPackage ||
		n.Kind == NotificationKindUpdatedParticipationPackage ||
		n.Kind == NotificationKindDeletedParticipationPackage ||
		n.Kind == NotificationKindUpdatedParticipationStatus {

		// at least one must exist
		valid = false
		valid = valid || n.Speaker != nil
		valid = valid || n.Company != nil

		if !valid {
			return errors.New("missing data")
		}
	} else if n.Kind == NotificationKindUpdatedCompanyImage {
		if n.Speaker == nil {
			return errors.New("missing data")
		}
	}

	return nil
}

// Hash gets the signature of this notification, given that will be used to notifiy some user
// This will avoid multiple identical notifications to the same user
func (n *Notification) Hash() string {

	digester := sha256.New()

	digester.Write([]byte(n.Kind))
	digester.Write([]byte(n.Member.Hex()))

	if n.Post != nil {
		digester.Write([]byte(n.Post.Hex()))
	}

	if n.Thread != nil {
		digester.Write([]byte(n.Thread.Hex()))
	}

	if n.Speaker != nil {
		digester.Write([]byte(n.Speaker.Hex()))
	}

	if n.Company != nil {
		digester.Write([]byte(n.Company.Hex()))
	}

	if n.Meeting != nil {
		digester.Write([]byte(n.Meeting.Hex()))
	}

	if n.Session != nil {
		digester.Write([]byte(n.Session.Hex()))
	}

	return hex.EncodeToString(digester.Sum(nil))
}

func (n *Notification) Equals(other *Notification) bool {

	if n == nil || other == nil {
		return false
	}

	return n.Signature == other.Signature
}
