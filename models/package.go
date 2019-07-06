package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type PackageItem struct {
	Item     primitive.ObjectID
	Quantity int
}

type Package struct {
	ID    primitive.ObjectID `json:"id" bson:"_id"`
	Name  string
	Items []PackageItem
	Price int
	VAT   int
}
