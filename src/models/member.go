package models

import "go.mongodb.org/mongo-driver/bson/primitive"


// Member represents a member of the SINFO organization
type Member struct {

	// Member's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name string `json:"name" bson:"name"`

	// Photo of the member. This is a URL pointing to the image, that is
	// being stored somewhere else.
	Image string `json:"img" bson:"img"`

	// Instituto Superior Técnico's Identification number of the member.
	// Can be left blank if non-applicable.
	ISTID string `json:"istid" bson:"istid"`

	// Contact is an _id of Contact (see models.Contact).
	Contact primitive.ObjectID `json:"contact" bson:"contact"`

	// Notifications is an array of _id of Notification (see models.Notification).
	Notifications []primitive.ObjectID `json:"notifications" bson:"notifications"`
}

// MemberPublic is the public information about a member
type MemberPublic struct{
	// Member's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name string `json:"name" bson:"name"`

	// Photo of the member. This is a URL pointing to the image, that is
	// being stored somewhere else.
	Image string `json:"img" bson:"img"`
}
