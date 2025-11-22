package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CoordinationTeam represents a dedicated coordination team separate from normal teams.
// It maps a set of coordinator members to the IDs of teams they coordinate.
type CoordinationTeam struct {
	ID   primitive.ObjectID `json:"id" bson:"_id"`
	Name string             `json:"name" bson:"name"`

	// Coordinators are members that act as coordinators for the configured teams.
	Coordinators []TeamMember `json:"coordinators" bson:"coordinators"`

	// CoordinatedMembers holds IDs of members (from models.Member) that belong to
	// this coordination team for the current event.
	CoordinatedMembers []primitive.ObjectID `json:"coordinatedMembers" bson:"coordinatedMembers"`
}

// HasCoordinator returns true if the given member is a coordinator in this coordination team.
func (ct *CoordinationTeam) HasCoordinator(member primitive.ObjectID) bool {
	for _, c := range ct.Coordinators {
		if c.Member == member {
			return true
		}
	}
	return false
}

// HasCoordinatedTeam returns true if this coordination team coordinates the provided team id.
func (ct *CoordinationTeam) HasCoordinatedMember(memberID primitive.ObjectID) bool {
	for _, m := range ct.CoordinatedMembers {
		if m == memberID {
			return true
		}
	}
	return false
}
