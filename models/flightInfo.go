package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// FlightInfo stores information about speakers' flights (see models.Speaker).
type FlightInfo struct {
	ID       primitive.ObjectID `json:"id" bson:"_id"`
	Inbound  time.Time          `json:"inbound" bson:"inbound"`
	Outbound time.Time          `json:"outbound" bson:"outbound"`

	// Airport
	From string `json:"from" bson:"from"`

	// Airport
	To string `json:"to" bson:"to"`

	// Link to the flight information
	Link string `json:"link" bson:"link"`

	Bought bool `json:"bought" bson:"bought"`

	// Cost of the flight in cents (€)
	Cost int `json:"cost" bson:"cost"`

	Notes string `json:"notes" bson:"notes"`
}
