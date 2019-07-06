package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type MeetingParticipants struct {
	Members     []primitive.ObjectID
	CompanyReps []primitive.ObjectID
}

type Meeting struct {
	ID           primitive.ObjectID `json:"id" bson:"_id"`
	Begin        time.Time
	End          time.Time
	Place        string
	Minute       string
	Participants MeetingParticipants
}
