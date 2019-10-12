package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// TeamsType contains database information on teams
type TeamsType struct {
	Collection *mongo.Collection
}

// CreateTeamData contains the data needed to create a team
type CreateTeamData struct {
	Name string `json:"name"`
}

// GetTeamsOptions contains filters for the GetTeams method
type GetTeamsOptions struct {
	Name       *string
	Event      *int
	Member     *primitive.ObjectID
	MemberName *string
}

// UpdateTeamMemberData contains data needed to update a team member
type UpdateTeamMemberData struct {
	Role *models.TeamRole `json:"role"`
}

// CreateTeamMemberData contains data needed to create a team member
type CreateTeamMemberData struct {
	Member primitive.ObjectID `json:"id"`
	Role   models.TeamRole    `json:"role"`
}

// ParseBody fills the CreateTeamData from a body
func (ctd *CreateTeamData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ctd); err != nil {
		return err
	}

	if len(ctd.Name) == 0 {
		return errors.New("invalid name")
	}

	return nil
}

// ParseBody fills the UpdateTeamMemberData from a body
func (utmd *UpdateTeamMemberData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(utmd); err != nil {
		log.Println("err 1")
		return err
	}

	if len(*utmd.Role) == 0 {
		return errors.New("invalid body")
	}

	if !(*utmd.Role).IsValidRole() {
		return errors.New("invalid role")
	}

	return nil
}

// ParseBody fills the UpdateTeamMemberData from a body
func (ctmd *CreateTeamMemberData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ctmd); err != nil {
		log.Println("err 1")
		return err
	}

	if len(ctmd.Role) == 0 {
		return errors.New("invalid body")
	}

	if !ctmd.Role.IsValidRole() {
		return errors.New("invalid role")
	}

	return nil
}

// CreateTeam creates a new team and adds it to the current event
func (t *TeamsType) CreateTeam(data CreateTeamData) (*models.Team, error) {
	ctx := context.Background()

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)
	var updatedEvent models.Event

	insertResult, err := t.Collection.InsertOne(ctx, bson.M{
		"name":     data.Name,
		"members":  []models.TeamMember{},
		"meetings": []primitive.ObjectID{},
	})
	if err != nil {
		return nil, err
	}

	newTeam, err := t.GetTeam(insertResult.InsertedID.(primitive.ObjectID))
	if err != nil {
		return nil, err
	}

	event, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	teams := append(event.Teams, newTeam.ID)

	var updateQuery = bson.M{
		"$set": bson.M{
			"teams": teams,
		},
	}

	if err = Events.Collection.FindOneAndUpdate(ctx, bson.M{"_id": event.ID}, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("Error updating events teams", err)
		return nil, err
	}

	return newTeam, nil
}

// GetTeam gets a team by its ID.
func (t *TeamsType) GetTeam(teamID primitive.ObjectID) (*models.Team, error) {
	ctx := context.Background()
	var team models.Team

	err := t.Collection.FindOne(ctx, bson.M{"_id": teamID}).Decode(&team)
	if err != nil {
		return nil, err
	}

	return &team, nil
}

// GetTeams gets all teams specified with a query.
// Options can be Event id, member id or team name
// Event id defaults to currentEvent.
func (t *TeamsType) GetTeams(options GetTeamsOptions) ([]*models.Team, error) {
	ctx := context.Background()
	var teams = make([]*models.Team, 0)
	var membersID = make([]primitive.ObjectID, 0)
	var event *models.Event
	var err error
	var filter = bson.M{}

	if options.Event != nil {
		event, err = Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}

		filter["_id"] = bson.M{"$in": event.Teams}
	}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex": fmt.Sprintf(".*%s.*", *options.Name),
		}
	}

	if options.MemberName != nil {
		members, err := Members.GetMembers(GetMemberOptions{Name: options.MemberName})
		if err != nil {
			return nil, err
		}

		for _, member := range members {
			fmt.Println(member.Name)
			membersID = append(membersID, member.ID)
		}
	}

	if options.Member != nil && options.MemberName == nil {
		filter["members.member"] = options.Member
	} else if options.Member != nil && options.MemberName != nil {
		filter["$or"] = []bson.M{
			bson.M{"members.member": options.Member},
			bson.M{"members.member": bson.M{"$in": membersID}},
		}
	} else if options.Member == nil && options.MemberName != nil {
		filter["members.member"] = bson.M{
			"$in": membersID,
		}
	}

	curr, err := t.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for curr.Next(ctx) {
		var team models.Team

		if err := curr.Decode(&team); err != nil {
			return nil, err
		}

		teams = append(teams, &team)
	}

	curr.Close(ctx)

	return teams, nil
}

// DeleteTeam deletes a team by its ID.
func (t *TeamsType) DeleteTeam(teamID primitive.ObjectID) (*models.Team, error) {
	ctx := context.Background()

	var team models.Team

	err := t.Collection.FindOneAndDelete(ctx, bson.M{"_id": teamID}).Decode(&team)
	if err != nil {
		return nil, err
	}

	return &team, nil
}

// UpdateTeam updates the team name.
func (t *TeamsType) UpdateTeam(teamID primitive.ObjectID, data CreateTeamData) (*models.Team, error) {
	ctx := context.Background()

	var team models.Team

	var updateQuery = bson.M{
		"$set": bson.M{
			"name": data.Name,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(ctx, bson.M{"_id": teamID}, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// AddTeamMember adds a member to a team.
func (t *TeamsType) AddTeamMember(id primitive.ObjectID, data CreateTeamMemberData) (*models.Team, error) {
	ctx := context.Background()

	var team models.Team
	var members []models.TeamMember

	// Check if member exists
	if _, err := Members.GetMember(data.Member); err != nil {
		return nil, err
	}

	team1, err := t.GetTeam(id)
	if err != nil {
		return nil, err
	}

	// Check for duplicate member
	if team1.HasMember(data.Member) {
		return nil, errors.New("Duplicate member")
	}

	members = append(team1.Members, models.TeamMember{
		Member: data.Member,
		Role:   data.Role,
	})

	var updateQuery = bson.M{
		"$set": bson.M{
			"members": members,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(ctx, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// UpdateTeamMemberRole changes the role of a team member
func (t *TeamsType) UpdateTeamMemberRole(teamID, memberID primitive.ObjectID, data UpdateTeamMemberData) (*models.Team, error) {
	ctx := context.Background()

	var team models.Team

	// Check if member exists
	if _, err := Members.GetMember(memberID); err != nil {
		return nil, err
	}

	_, err := t.GetTeam(teamID)
	if err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"members.$.role": data.Role,
		},
	}

	var filterQuery = bson.M{
		"_id":            teamID,
		"members.member": memberID,
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// DeleteTeamMember removes a member from a team.
func (t *TeamsType) DeleteTeamMember(id, memberID primitive.ObjectID) (*models.Team, error) {
	ctx := context.Background()

	var team models.Team
	var members []models.TeamMember

	// Check if member exists
	if _, err := Members.GetMember(memberID); err != nil {
		return nil, err
	}

	team1, err := t.GetTeam(id)
	if err != nil {
		return nil, err
	}

	// Check for non-existent member
	if !team1.HasMember(memberID) {
		return nil, errors.New("Member not found")
	}

	for i, s := range team1.Members {
		if s.Member == memberID {
			members = append(team1.Members[:i], team1.Members[i+1:]...)
			break
		}
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"members": members,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(ctx, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// AddMeeting creates and adds a meeting to a team
func (t *TeamsType) AddMeeting(id, meeting primitive.ObjectID) (*models.Team, error) {
	ctx := context.Background()

	team, err := t.GetTeam(id)
	if err != nil {
		return nil, err
	}

	var result models.Team

	var meets = append(team.Meetings, meeting)

	var updateQuery = bson.M{
		"$set": bson.M{
			"meetings": meets,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err = t.Collection.FindOneAndUpdate(ctx, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

// DeleteTeamMeeting removes a meeting from a team
func (t *TeamsType) DeleteTeamMeeting(teamID, meetingID primitive.ObjectID) (*models.Meeting, error) {
	ctx := context.Background()

	team, err := t.GetTeam(teamID)
	if err != nil {
		return nil, errors.New("Team not found")
	}

	if !team.HasMeeting(meetingID) {
		return nil, errors.New("Meeting not in team")
	}

	meeting, err := Meetings.GetMeeting(meetingID)
	if err != nil {
		return nil, errors.New("Meeting not found")
	}

	var meetings []primitive.ObjectID
	var updatedTeam models.Team

	for i, s := range team.Meetings {
		if s == meetingID {
			meetings = append(team.Meetings[:i], team.Meetings[i+1:]...)
			break
		}
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"meetings": meetings,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err = t.Collection.FindOneAndUpdate(ctx, bson.M{"_id": teamID}, updateQuery, optionsQuery).Decode(&updatedTeam); err != nil {
		return nil, err
	}

	return meeting, nil
}

//GetMembersByRole gets all members that match specified role
func (t *TeamsType) GetMembersByRole(role models.TeamRole) ([]primitive.ObjectID, error) {
	ctx := context.Background()

	var members = make([]primitive.ObjectID, 0)

	if !role.IsValidRole() {
		return nil, errors.New("invalid role")
	}

	var query = []bson.M{
		bson.M{"$match": bson.M{"members.role": role}},
		bson.M{"$project": bson.M{
			"_id": 0,
			"members": bson.M{
				"$filter": bson.M{
					"input": "$members",
					"as":    "member",
					"cond":  bson.M{"$eq": []string{"$$member.role", string(role)}},
				},
			},
		}},
		bson.M{
			"$unwind": "$members",
		},
		bson.M{
			"$group": bson.M{"_id": "$members.member"},
		},
	}

	type QueryResult struct {
		ID primitive.ObjectID `bson:"_id"`
	}

	cur, err := t.Collection.Aggregate(ctx, query)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {
		var result QueryResult
		if err := cur.Decode(&result); err != nil {
			return nil, err
		}
		members = append(members, result.ID)
	}

	cur.Close(ctx)

	return members, nil
}
