package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type Notification struct {
	ID          primitive.ObjectID `json:"id" bson:"_id"`
	Post        primitive.ObjectID
	Speaker     primitive.ObjectID
	Meeting     primitive.ObjectID
	Description string
}
