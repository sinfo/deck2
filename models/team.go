package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type TeamMembers struct {
	Member primitive.ObjectID
	Role   string
}

type Team struct {
	ID       primitive.ObjectID
	Name     string
	Members  []TeamMembers
	Meetings []primitive.ObjectID
}
