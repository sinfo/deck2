package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type MeetingParticipants struct {

	// Members is an array of _id of Member (see models.Member).
	Members []primitive.ObjectID `json:"members" bson:"members"`

	// CompanyReps is an array of _id of CompanyRep (see models.CompanyRep).
	CompanyReps []primitive.ObjectID `json:"companyReps" bson:"companyReps"`
}

// Meeting stores informations abouts meetings with the SINFO team,
// or meetings scheduled with companies.
type Meeting struct {

	// Meeting's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Begin time.Time `json:"begin" bson:"begin"`
	End   time.Time `json:"end" bson:"end"`

	// Place where the meeting is being held.
	Place string `json:"place" bson:"place"`

	// A written record of the meeting. This is typically a URL to where the
	// actual document is being stored.
	// "Ata" in portuguese.
	Minute string `json:"minute" bson:"minute"`

	Participants MeetingParticipants `json:"participants" bson:"participants"`
}
