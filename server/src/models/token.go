package models

import (
	"time"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Token struct {
	ID		primitive.ObjectID	`json:"id" bson:"_id"`
	Expiry	time.Time 			`json:"expiry" bson:"expiry"`
	Refresh	string				`json:"refresh" bson:"refresh"`
	Access	string				`json:"access" bson:"access"`
}