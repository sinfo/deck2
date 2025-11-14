package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Log represents an immutable record of an action performed in the system
type Log struct {
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// Actor is the member who performed the action (if applicable)
	Actor *primitive.ObjectID `json:"actor,omitempty" bson:"actor"`

	// Action is a short identifier of the action performed (e.g. "CREATE_COMPANY")
	Action string `json:"action" bson:"action"`

	// Resource is the type of resource acted upon (e.g. "company", "speaker", "meeting")
	Resource string `json:"resource" bson:"resource"`

	// ResourceID is the id of the resource (when applicable)
	ResourceID *primitive.ObjectID `json:"resourceId,omitempty" bson:"resourceId,omitempty"`

	// Data contains extra contextual information relevant to the log entry
	Data map[string]interface{} `json:"data,omitempty" bson:"data,omitempty"`

	// Event is the edition/event id this log is associated with (when applicable)
	Event int `json:"event,omitempty" bson:"event,omitempty"`

	// Date is the timestamp the log was created
	Date time.Time `json:"date" bson:"date"`
}
