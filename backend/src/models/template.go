package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Template struct {

	// template's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name string `json:"name" bson:"name"`
	Url  string `json:"url" bson:"url"`
	// Event (edition) this template is associated with. Optional.
	Event        int           `json:"event,omitempty" bson:"event,omitempty"`
	Requirements []Requirement `json:"requirements" bson:"requirements"`
	Kind         string        `json:"kind" bson:"kind"`
}
