package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type Thread struct {
	ID          primitive.ObjectID
	Entry       primitive.ObjectID
	Meeting     primitive.ObjectID
	Comments    []primitive.ObjectID
	Kind        string
	Status      string
	Subscribers []primitive.ObjectID
}
