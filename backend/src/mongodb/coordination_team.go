package mongodb

import (
	"context"
	"errors"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// CoordinationTeamsType contains database info for coordination teams
type CoordinationTeamsType struct {
	Collection *mongo.Collection
}

// CreateCoordinationTeam inserts a new coordination team
func (c *CoordinationTeamsType) CreateCoordinationTeam(name string) (*models.CoordinationTeam, error) {
	ctx := context.Background()

	insertResult, err := c.Collection.InsertOne(ctx, bson.M{
		"name":               name,
		"coordinators":       []models.TeamMember{},
		"coordinatedMembers": []primitive.ObjectID{},
	})
	if err != nil {
		return nil, err
	}

	id := insertResult.InsertedID.(primitive.ObjectID)
	return c.GetCoordinationTeam(id)
}

// GetCoordinationTeam retrieves a coordination team by ID
func (c *CoordinationTeamsType) GetCoordinationTeam(id primitive.ObjectID) (*models.CoordinationTeam, error) {
	ctx := context.Background()
	var ct models.CoordinationTeam
	if err := c.Collection.FindOne(ctx, bson.M{"_id": id}).Decode(&ct); err != nil {
		return nil, err
	}
	return &ct, nil
}

// GetCoordinationTeamsByMember finds coordination teams that include the given member id
func (c *CoordinationTeamsType) GetCoordinationTeamsByMember(memberID primitive.ObjectID) ([]*models.CoordinationTeam, error) {
	ctx := context.Background()
	cur, err := c.Collection.Find(ctx, bson.M{"coordinatedMembers": memberID})
	if err != nil {
		return nil, err
	}

	var res []*models.CoordinationTeam
	for cur.Next(ctx) {
		var ct models.CoordinationTeam
		if err := cur.Decode(&ct); err != nil {
			return nil, err
		}
		res = append(res, &ct)
	}
	cur.Close(ctx)
	return res, nil
}

// GetCoordinationTeamsByCoordinator finds coordination teams where the provided member is a coordinator
func (c *CoordinationTeamsType) GetCoordinationTeamsByCoordinator(memberID primitive.ObjectID) ([]*models.CoordinationTeam, error) {
	ctx := context.Background()
	cur, err := c.Collection.Find(ctx, bson.M{"coordinators.member": memberID})
	if err != nil {
		return nil, err
	}

	var res []*models.CoordinationTeam
	for cur.Next(ctx) {
		var ct models.CoordinationTeam
		if err := cur.Decode(&ct); err != nil {
			return nil, err
		}
		res = append(res, &ct)
	}
	cur.Close(ctx)
	return res, nil
}

// AddCoordinatedMember adds a member id to the coordinatedMembers list
func (c *CoordinationTeamsType) AddCoordinatedMember(coordTeamID, memberID primitive.ObjectID) (*models.CoordinationTeam, error) {
	ctx := context.Background()

	ct, err := c.GetCoordinationTeam(coordTeamID)
	if err != nil {
		return nil, err
	}

	for _, m := range ct.CoordinatedMembers {
		if m == memberID {
			return nil, errors.New("already exists")
		}
	}

	ct.CoordinatedMembers = append(ct.CoordinatedMembers, memberID)

	if _, err := c.Collection.UpdateOne(ctx, bson.M{"_id": coordTeamID}, bson.M{"$set": bson.M{"coordinatedMembers": ct.CoordinatedMembers}}); err != nil {
		return nil, err
	}

	return c.GetCoordinationTeam(coordTeamID)
}

// RemoveCoordinatedMember removes a member id from the coordinatedMembers list
func (c *CoordinationTeamsType) RemoveCoordinatedMember(coordTeamID, memberID primitive.ObjectID) (*models.CoordinationTeam, error) {
	ctx := context.Background()

	ct, err := c.GetCoordinationTeam(coordTeamID)
	if err != nil {
		return nil, err
	}

	found := false
	newList := make([]primitive.ObjectID, 0, len(ct.CoordinatedMembers))
	for _, m := range ct.CoordinatedMembers {
		if m == memberID {
			found = true
			continue
		}
		newList = append(newList, m)
	}

	if !found {
		return nil, errors.New("not found")
	}

	if _, err := c.Collection.UpdateOne(ctx, bson.M{"_id": coordTeamID}, bson.M{"$set": bson.M{"coordinatedMembers": newList}}); err != nil {
		return nil, err
	}

	return c.GetCoordinationTeam(coordTeamID)
}

// SetCoordinator sets the single coordinator for this coordination team. It replaces existing coordinators.
// If name is non-empty it will also update the coordination team's name in the same operation.
func (c *CoordinationTeamsType) SetCoordinator(coordTeamID primitive.ObjectID, member models.TeamMember, name string) (*models.CoordinationTeam, error) {
	ctx := context.Background()

	if member.Role != models.RoleCoordinator {
		member.Role = models.RoleCoordinator
	}

	set := bson.M{"coordinators": []models.TeamMember{member}}
	if len(name) > 0 {
		set["name"] = name
	}

	if _, err := c.Collection.UpdateOne(ctx, bson.M{"_id": coordTeamID}, bson.M{"$set": set}); err != nil {
		return nil, err
	}

	return c.GetCoordinationTeam(coordTeamID)
}

// RemoveCoordinator removes a coordinator by member id
func (c *CoordinationTeamsType) RemoveCoordinator(coordTeamID, memberID primitive.ObjectID) (*models.CoordinationTeam, error) {
	ctx := context.Background()

	ct, err := c.GetCoordinationTeam(coordTeamID)
	if err != nil {
		return nil, err
	}

	newList := make([]models.TeamMember, 0, len(ct.Coordinators))
	found := false
	for _, m := range ct.Coordinators {
		if m.Member == memberID {
			found = true
			continue
		}
		newList = append(newList, m)
	}

	if !found {
		return nil, errors.New("not found")
	}

	if _, err := c.Collection.UpdateOne(ctx, bson.M{"_id": coordTeamID}, bson.M{"$set": bson.M{"coordinators": newList}}); err != nil {
		return nil, err
	}

	return c.GetCoordinationTeam(coordTeamID)
}

// UpdateName updates the coordination team's name
func (c *CoordinationTeamsType) UpdateName(coordTeamID primitive.ObjectID, name string) (*models.CoordinationTeam, error) {
	ctx := context.Background()

	if _, err := c.Collection.UpdateOne(ctx, bson.M{"_id": coordTeamID}, bson.M{"$set": bson.M{"name": name}}); err != nil {
		return nil, err
	}

	return c.GetCoordinationTeam(coordTeamID)
}

// GetAllCoordinationTeams lists all coordination teams
func (c *CoordinationTeamsType) GetAllCoordinationTeams() ([]*models.CoordinationTeam, error) {
	ctx := context.Background()
	cur, err := c.Collection.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}

	var res []*models.CoordinationTeam
	for cur.Next(ctx) {
		var ct models.CoordinationTeam
		if err := cur.Decode(&ct); err != nil {
			return nil, err
		}
		res = append(res, &ct)
	}
	cur.Close(ctx)
	return res, nil
}

// DeleteCoordinationTeam deletes a coordination team and returns the deleted document
func (c *CoordinationTeamsType) DeleteCoordinationTeam(coordTeamID primitive.ObjectID) (*models.CoordinationTeam, error) {
	ctx := context.Background()

	ct, err := c.GetCoordinationTeam(coordTeamID)
	if err != nil {
		return nil, err
	}

	delRes, err := c.Collection.DeleteOne(ctx, bson.M{"_id": coordTeamID})
	if err != nil {
		return nil, err
	}

	if delRes.DeletedCount != 1 {
		return nil, errors.New("could not delete coordination team")
	}

	return ct, nil
}
