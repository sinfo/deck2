package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

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

	// SINFOID is the member's identifier ID under the SINFO organization
	// Example: if the member's SINFO email is john.doe@sinfo.org, his sinfo ID would be john.doe
	SINFOID string `json:"sinfoid" bson:"sinfoid"`

	// Contact is an _id of Contact (see models.Contact).
	Contact primitive.ObjectID `json:"contact" bson:"contact"`
}

// MemberPublic is the public information about a member
type MemberPublic struct {
	Name string `json:"name" bson:"name"`

	// Photo of the member. This is a URL pointing to the image, that is
	// being stored somewhere else.
	Image string `json:"img" bson:"img"`

	Socials ContactSocials `json:"socials"`
}

type AuthorizationCredentials struct {
	// Member's ID
	ID primitive.ObjectID

	// SINFO's email ID (example: if your email is john.doe@sinfo.org, your emailID would be john.doe)
	SINFOID string

	// Role on SINFO
	Role TeamRole
}

type MemberEventTeam struct {
	//Number of event where Member was in <Team>
	Event int

	//Team of Member on SINFO <Event>
	Team string

	// Role on SINFO <Event>
	Role TeamRole
}
