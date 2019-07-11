package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type PackageItem struct {

	// Item is an _id of Item (see models.Item).
	Item primitive.ObjectID `json:"item" bson:"item"`

	// Quantity of the item, if applicable. For example, 2 posts on social networks, or
	// 3 stand days on the event week.
	Quantity int `json:"quantity" bson:"quantity"`
}

// Package represents a bundle of items associated with a price to be presented to the companies.
// On previous editions, packages like "Silver", "Gold", "Platinum" and "Diamond" where used to
// describe certains bundles of perks given to the companies. With this, the dynamic creation of packages
// is possible, allowing there to be different packages on different events.
type Package struct {

	// Package's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name  string        `json:"name" bson:"name"`
	Items []PackageItem `json:"items" bson:"items"`

	// Price in cents (€).
	Price int `json:"price" bson:"price"`

	// Value of taxes in percentage (%). The total value will be value = Price * (1 + VAT).
	VAT int `json:"vat" bson:"vat"`
}
