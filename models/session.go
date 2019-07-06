package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type SessionDinamizers struct {
	Name     string
	Position string
}

type Session struct {
	ID          primitive.ObjectID `json:"id" bson:"_id"`
	Begin       time.Time
	End         time.Time
	Title       string
	Description string
	Space       string
	Kind        string
	Company     primitive.ObjectID
	SessionDinamizers
	Speaker  primitive.ObjectID
	VideoURL string
}
