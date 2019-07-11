package models

import "go.mongodb.org/mongo-driver/bson/primitive"

// Notification is created to warn a Member about a change to a certain entity
// (Post, Speaker, Company or Meeting). This will be added to the Member
// if he/she is on the entity's subscribers' list.
type Notification struct {

	// Notification's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// Post is an _id of Post (see models.Post).
	Post primitive.ObjectID `json:"post" bson:"post"`

	// Speaker is an _id of Speaker (see models.Speaker).
	Speaker primitive.ObjectID `json:"speaker" bson:"speaker"`

	// Company is an _id of Company (see models.Company).
	Company primitive.ObjectID `json:"company" bson:"company"`

	// Meeting is an _id of Meeting (see models.Meeting).
	Meeting primitive.ObjectID `json:"meeting" bson:"meeting"`

	Description string `json:"description" bson:"description"`
}
