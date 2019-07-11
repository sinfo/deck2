package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SessionDinamizers are company's employers that will give the presentation.
// Only applicable if the session is associated with a company.
type SessionDinamizers struct {
	Name     string `json:"name" bson:"name"`
	Position string `json:"position" bson:"position"`
}

// Session is a scheduled talk, presentation or workshop. This will be used to generate
// the event's week schedule.
type Session struct {

	// Session's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Begin       time.Time `json:"begin" bson:"begin"`
	End         time.Time `json:"end" bson:"end"`
	Title       string    `json:"title" bson:"title"`
	Description string    `json:"description" bson:"description"`

	// Where the session is being held. Typically a room on the venue.
	Space string `json:"space" bson:"space"`

	// Kind of session can be "TALK", "PRESENTATION" or "WORKSHOP".
	Kind string `json:"kind" bson:"kind"`

	// Company is an _id of Company (see models.Company).
	Company primitive.ObjectID `json:"company" bson:"company"`

	SessionDinamizers `json:"dinamizers" bson:"dinamizers"`

	// Speaker is an _id of Speaker (see models.Speaker).
	Speaker primitive.ObjectID `json:"speaker" bson:"speaker"`

	// Video of the session, if applicable. Typically a youtube URL.
	VideoURL string `json:"videoURL" bson:"videoURL"`
}
