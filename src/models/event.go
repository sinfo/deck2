package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type EventPackages struct {

	// Template is a Package _id (see models.Package).
	Template primitive.ObjectID `json:"template" bson:"template"`

	Available bool `json:"available" bson:"available"`
}

type EventItems struct {

	// Item is a Item _id (see models.Item).
	Item primitive.ObjectID `json:"item" bson:"item"`

	Available bool `json:"available" bson:"available"`
}

// Event info.
type Event struct {

	// Event's ID (_id of mongodb).
	// Example: SINFO 26 has id=26.
	ID int `json:"id" bson:"_id"`

	Name  string     `json:"name" bson:"name"`
	Begin *time.Time `json:"begin,omitempty" bson:"begin,omitempty"`
	End   *time.Time `json:"end,omitempty" bson:"end,omitempty"`

	// Event days' themes.
	// Each index of the array corresponds to a week day during the event.
	// Example: index 1 corresponds to monday, index 2 to tuesday, etc).
	// The themes can be "Software Engineer", "Security", "Gaming", etc.
	Themes []string `json:"themes" bson:"themes"`

	Packages []EventPackages `json:"packages" bson:"packages"`
	Items    []EventItems    `json:"items" bson:"items"`

	// Meetings is an array of Meeting _id (see models.Meeting).
	Meetings []primitive.ObjectID `json:"meetings" bson:"meetings"`

	// Sessions is an array of Session _id (see models.Session).
	Sessions []primitive.ObjectID `json:"sessions" bson:"sessions"`
}
