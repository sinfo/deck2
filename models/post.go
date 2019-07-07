package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Post struct {

	// Post's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// Member is an _id of Member (see models.Member).
	Member primitive.ObjectID `json:"member" bson:"member"`

	// Actual content of the post.
	Text string `json:"text" bson:"text"`

	Posted  time.Time `json:"posted" bson:"posted"`
	Updated time.Time `json:"updated" bson:"updated"`
}
