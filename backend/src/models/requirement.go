package models

// import (
// 	"go.mongodb.org/mongo-driver/bson/primitive"
// )

type Requirement struct {

	// template's ID (_id of mongodb).
	//ID    primitive.ObjectID `json:"id" bson:"_id"`
	Title       string `json:"title"`
	Name        string `json:"name"`
	StringValue string `json:"stringVal"`
	BoolValue   bool   `json:"boolVal"`
	Type        string `json:"type"`
}
