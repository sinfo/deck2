package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type TeamMembers struct {

	// Member is an _id of Member (see models.Member).
	Member primitive.ObjectID `json:"member" bson:"member"`

	// Role of the member on this team (typically "Team Leader" or "Member").
	Role string `json:"role" bson:"role"`
}

// Team struct
type Team struct {

	// Team's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// Examples: DevTeam, Logistics, etc.
	Name string `json:"name" bson:"name"`

	Members []TeamMembers `json:"members" bson:"members"`

	// Meetings is an array of Meeting (see models.Meeting).
	// This represents meetings specific to this team.
	Meetings []primitive.ObjectID `json:"meetings" bson:"meetings"`
}

// TeamPublic info
type TeamPublic struct {
	ID		primitive.ObjectID		`json:"id" bson:"_id"` 
	Name	string 					`json:"name" bson:"name"`
	Members	[]TeamMembers	`json:"members" bson:"members"`
}


// HasMember returns true if member is in the team and false otherwise.
func (t *Team) HasMember(member primitive.ObjectID) bool {
	for _, s := range t.Members {
		if s.Member == member {
			return true
		}
	}
	return false
}

// HasMember returns true if member is in the team and false otherwise.
func (t *TeamPublic) HasMember(member primitive.ObjectID) bool {
	for _, s := range t.Members {
		if s.Member == member {
			return true
		}
	}
	return false
}
