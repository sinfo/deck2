package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// BillingStatus is the status of the bill.
type BillingStatus struct {
	ProForma bool `json:"proForma" bson:"proForma"`
	Invoice  bool `json:"invoice" bson:"invoice"`
	Receipt  bool `json:"receipt" bson:"receipt"`
	Paid     bool `json:"paid" bson:"paid"`
}

// Billing (used on company participations).
type Billing struct {
	ID     primitive.ObjectID `json:"id" bson:"_id"`
	Status BillingStatus      `json:"status" bson:"status"`

	Event int `json:"event" bson:"event"`

	///Company is optional
	Company *primitive.ObjectID `json:"company,omitempty" bson:"company,omitempty"`

	// Value is the billing value in cents (€).
	Value int `json:"value" bson:"value"`

	InvoiceNumber string    `json:"invoiceNumber" bson:"invoiceNumber"`
	Emission      time.Time `json:"emission" bson:"emission"`
	Notes         string    `json:"notes" bson:"notes"`
	Visible       bool      `json:"visible" bson:"visible"`
}
