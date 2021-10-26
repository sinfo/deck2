package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ThreadKind is the type of thread
type ThreadKind string

const (
	ThreadKindTemplate  ThreadKind = "TEMPLATE"
	ThreadKindTo        ThreadKind = "TO"
	ThreadKindFrom      ThreadKind = "FROM"
	ThreadKindPhoneCall ThreadKind = "PHONE_CALL"
	ThreadKindMeeting   ThreadKind = "MEETING"
)

// IsValid check the validity the thread kind
func (tk ThreadKind) IsValid() bool {
	return tk == ThreadKindTemplate ||
		tk == ThreadKindTo ||
		tk == ThreadKindFrom ||
		tk == ThreadKindPhoneCall ||
		tk == ThreadKindMeeting
}

// ThreadStatus is the status of the thread
type ThreadStatus string

const (
	ThreadStatusApproved ThreadStatus = "APPROVED"
	ThreadStatusReviewed ThreadStatus = "REVIEWED"
	ThreadStatusPending  ThreadStatus = "PENDING"
)

// IsValid check the validity the thread status
func (ts ThreadStatus) IsValid() bool {
	return ts != ThreadStatusApproved && ts != ThreadStatusReviewed && ts != ThreadStatusPending
}

type Thread struct {

	// Thread's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// Time posted
	Posted  time.Time `json:"posted" bson:"posted"`

	// Entry is an _id of Post (see models.Post).
	Entry primitive.ObjectID `json:"entry" bson:"entry"`

	// Meeting is an _id of Meeting (see models.Meeting).
	Meeting *primitive.ObjectID `json:"meeting,omitempty" bson:"meeting,omitempty"`

	// Comments is an array of _id of Post (see models.Post).
	Comments []primitive.ObjectID `json:"comments" bson:"comments"`

	// Kind of thread can be "TO", "FROM", "PHONE_CALL", "MEETING".
	// This represents the type of communication made with a certain Company/Speaker.
	Kind ThreadKind `json:"kind" bson:"kind"`

	// Status of this thread can be "APPROVED", "REVIEWED", "PENDING".
	// APPROVED => thread is posted and approved by the coordination.
	// REVIEWED => thread is posted, but some changed must be made before it's ready to be approved.
	// PENDING => thread is posted and is waiting for the coordination's approval/review.
	Status ThreadStatus `json:"status" bson:"status"`
}
