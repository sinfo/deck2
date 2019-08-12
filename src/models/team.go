package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"

	"errors"
)

type TeamRole string

const (
	RoleMember      TeamRole = "MEMBER"
	RoleTeamLeader  TeamRole = "TEAMLEADER"
	RoleCoordinator TeamRole = "COORDINATOR"
	RoleAdmin       TeamRole = "ADMIN"
)

func (r TeamRole) IsValidRole() bool {
	if r == RoleMember {
		return true
	}

	if r == RoleTeamLeader {
		return true
	}

	if r == RoleCoordinator {
		return true
	}

	if r == RoleAdmin {
		return true
	}

	return false
}

// AccessLevel gets the acess level of the member based on this team. Lower values imply more permissions.
func (r TeamRole) AccessLevel() int {
	if r == RoleMember {
		return 3
	}

	if r == RoleTeamLeader {
		return 2
	}

	if r == RoleCoordinator {
		return 1
	}

	if r == RoleAdmin {
		return 0
	}

	return -1
}

type TeamMember struct {

	// Member is an _id of Member (see models.Member).
	Member primitive.ObjectID `json:"member" bson:"member"`

	// Role of the member on this team (typically "Team Leader" or "Member").
	Role TeamRole `json:"role" bson:"role"`
}

// Team struct
type Team struct {

	// Team's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// Examples: DevTeam, Logistics, etc.
	Name string `json:"name" bson:"name"`

	Members []TeamMember `json:"members" bson:"members"`

	// Meetings is an array of Meeting (see models.Meeting).
	// This represents meetings specific to this team.
	Meetings []primitive.ObjectID `json:"meetings" bson:"meetings"`
}

// TeamPublic info
type TeamPublic struct {
	ID		primitive.ObjectID		`json:"id" bson:"_id"` 
	Name	string 					`json:"name" bson:"name"`
	Members	[]TeamMember	`json:"members" bson:"members"`
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

func (t *TeamPublic) HasMember(member primitive.ObjectID) bool {
	for _, s := range t.Members {
		if s.Member == member {
			return true
		}
	}
	return false
}

// GetMember gets a member from a specific team
func (t *Team) GetMember(memberID primitive.ObjectID) (*TeamMember, error) {

	for _, m := range t.Members {
		if m.Member == memberID {
			return &m, nil
		}
	}

	return nil, errors.New("member not found")
}

// HasMeeting returns true if a team contains specified meeting
func (t *Team) HasMeeting(id primitive.ObjectID) bool {
	for _,s := range t.Meetings{
		if s == id{
			return true
		}
	}
	return false
}