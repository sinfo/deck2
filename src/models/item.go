package models

import "go.mongodb.org/mongo-driver/bson/primitive"

// Item used on the packages.
// They can be publicity items (posts on Facebook), number of stand days, size of logo on the website, etc
type Item struct {

	// Item's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name string `json:"name" bson:"name"`

	// Type represents the type of item. This is dynamic and decided on each Event by the Coordination,
	// but it can be, for example, "Publicity", "Merchandise", "Stands", "Talk"...
	Type        string `json:"type" bson:"type"`
	Description string `json:"description" bson:"description"`

	// This is a visual representation of the item. For example, in a merchandise item, it could be a photo.
	Image string `json:"img" bson:"img"`

	// Price in cents (€).
	Price int `json:"price" bson:"price"`

	// Tax percentage. The total value will be Price * (1 + VAT).
	VAT int `json:"vat" bson:"vat"`
}
