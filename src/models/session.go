package models

import (
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type SessionKind string

const (
	SessionKindTalk         SessionKind = "TALK"
	SessionKindPresentation SessionKind = "PRESENTATION"
	SessionKindWorkshop     SessionKind = "WORKSHOP"
)

func (sk *SessionKind) Parse(kind string) error {

	var newSessionKind SessionKind

	switch kind {

	case string(SessionKindTalk):
		newSessionKind = SessionKindTalk
		break

	case string(SessionKindPresentation):
		newSessionKind = SessionKindPresentation
		break

	case string(SessionKindWorkshop):
		newSessionKind = SessionKindWorkshop
		break

	default:
		return errors.New("invalid kind")

	}

	*sk = newSessionKind
	return nil
}

// SessionDinamizers are company's employers that will give the presentation.
// Only applicable if the session is associated with a company.
type SessionDinamizers struct {
	Name     string `json:"name" bson:"name"`
	Position string `json:"position" bson:"position"`
}

// SessionTickets are the session's reservation tickets' details.
// For example, if a workshop is ment to be given for 20 people, then
// there should be a maximum of 20 tickets available.
type SessionTickets struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
	Max   int       `json:"max"`
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
	Kind SessionKind `json:"kind" bson:"kind"`

	// Company is an _id of Company (see models.Company).
	Company *primitive.ObjectID `json:"company" bson:"company"`

	SessionDinamizers []SessionDinamizers `json:"dinamizers" bson:"dinamizers"`

	// Speaker is an _id of Speaker (see models.Speaker).
	Speaker *primitive.ObjectID `json:"speaker" bson:"speaker"`

	// Video of the session, if applicable. Typically a youtube URL.
	VideoURL string `json:"videoURL" bson:"videoURL"`

	Tickets *SessionTickets `json:"tickets,omitempty" bson:"tickets"`
}

// SessionPublic represents a session to be shown to everyone publicly.
type SessionPublic struct {
	Begin       time.Time `json:"begin"`
	End         time.Time `json:"end"`
	Title       string    `json:"title"`
	Description string    `json:"description"`

	// Where the session is being held. Typically a room on the venue.
	Space string `json:"space"`

	// Kind of session can be "TALK", "PRESENTATION" or "WORKSHOP".
	Kind SessionKind `json:"kind"`

	CompanyPublic *CompanyPublic `json:"company,omitempty"`

	SessionDinamizers []SessionDinamizers `json:"dinamizers"`

	// Speaker is an _id of Speaker (see models.Speaker).
	SpeakerPublic *SpeakerPublic `json:"speaker,omitempty"`

	// Video of the session, if applicable. Typically a youtube URL.
	VideoURL string `json:"videoURL,omitempty"`

	Tickets *SessionTickets `json:"tickets,omitempty" bson:"tickets"`
}
