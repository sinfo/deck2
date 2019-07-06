package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type Member struct {
	ID            primitive.ObjectID `json:"id" bson:"_id"`
	Name          string
	Image         string
	ISTID         string
	Contact       primitive.ObjectID
	Notifications []primitive.ObjectID
}
