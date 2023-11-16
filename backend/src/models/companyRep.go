package models

import "go.mongodb.org/mongo-driver/bson/primitive"

// CompanyRep represents a name and contact information related to some company's representative.
type CompanyRep struct {

	// CompanyRep's ID (_id of mongodb).
	ID   primitive.ObjectID `json:"id" bson:"_id"`
	Name string             `json:"name" bson:"name"`

	// Contact is a Contact _id (see models.Contact).
	Contact primitive.ObjectID `json:"contact" bson:"contact"`
}
