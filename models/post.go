package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Post struct {
	ID      primitive.ObjectID `json:"id" bson:"_id"`
	Member  primitive.ObjectID
	Text    string
	Posted  time.Time
	Updated time.Time
}
