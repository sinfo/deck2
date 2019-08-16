package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"strings"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// TeamsType contains database information on teams
type TeamsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// CreateTeamData contains the data needed to create a team
type CreateTeamData struct {
	Name string `json:"name"`
}

// GetTeamsOptions contains filters for the GetTeams method
type GetTeamsOptions struct {
	Name   *string
	Event  *int
	Member *primitive.ObjectID
}

// UpdateTeamMemberData contains data needed to update or create a team member
type UpdateTeamMemberData struct {
	Member *primitive.ObjectID `json:"member"`
	Role   *models.TeamRole    `json:"role"`
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

// CreateTeam creates a new team and adds it to the current event
func (t *TeamsType) CreateTeam(data CreateTeamData) (*models.Team, error) {

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)
	var updatedEvent models.Event

	insertResult, err := t.Collection.InsertOne(t.Context, bson.M{
		"name": data.Name,
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

	if err = Events.Collection.FindOneAndUpdate(Events.Context, bson.M{"_id": event.ID}, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("Error updating events teams", err)
		return nil, err
	}

	currentEvent = &updatedEvent

	return newTeam, nil
}

// GetTeam gets a team by its ID.
func (t *TeamsType) GetTeam(teamID primitive.ObjectID) (*models.Team, error) {
	var team models.Team

	err := t.Collection.FindOne(t.Context, bson.M{"_id": teamID}).Decode(&team)
	if err != nil {
		return nil, err
	}

	return &team, nil
}

// GetTeams gets all teams specified with a query.
// Options can be Event id, member id or team name
// Event id defaults to currentEvent.
func (t *TeamsType) GetTeams(options GetTeamsOptions) ([]*models.Team, error) {
	var teams = make([]*models.Team, 0)
	var event *models.Event
	var err error

	if options.Event != nil {
		event, err = Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}
	} else {
		event, err = Events.GetCurrentEvent()
		if err != nil {
			return nil, err
		}
	}

	for _, s := range event.Teams {
		team, err := t.GetTeam(s)
		if err != nil {
			return nil, err
		}
		if options.Name == nil {
			if options.Member == nil {
				teams = append(teams, team)
			} else if team.HasMember(*options.Member) {
				teams = append(teams, team)
			}
		} else if strings.Contains(strings.ToLower(team.Name), strings.ToLower(*options.Name)) {
			if options.Member == nil {
				teams = append(teams, team)
			} else if team.HasMember(*options.Member) {
				teams = append(teams, team)
			}
		}
	}

	return teams, nil
}

// DeleteTeam deletes a team by its ID.
func (t *TeamsType) DeleteTeam(teamID primitive.ObjectID) (*models.Team, error) {

	var team models.Team

	err := t.Collection.FindOneAndDelete(t.Context, bson.M{"_id": teamID}).Decode(&team)
	if err != nil {
		return nil, err
	}

	return &team, nil
}

// UpdateTeam updates the team name.
func (t *TeamsType) UpdateTeam(teamID primitive.ObjectID, data CreateTeamData) (*models.Team, error) {

	var team models.Team

	var updateQuery = bson.M{
		"$set": bson.M{
			"name": data.Name,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(t.Context, bson.M{"_id": teamID}, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// AddTeamMember adds a member to a team.
func (t *TeamsType) AddTeamMember(id primitive.ObjectID, data UpdateTeamMemberData) (*models.Team, error) {

	var team models.Team
	var members []models.TeamMember

	// Check if member exists
	if _, err := Members.GetMember(*data.Member); err != nil {
		return nil, err
	}

	team1, err := t.GetTeam(id)
	if err != nil {
		return nil, err
	}

	// Check for duplicate member
	if team1.HasMember(*data.Member) {
		return nil, errors.New("Duplicate member")
	}

	members = append(team1.Members, models.TeamMember{
		Member: *data.Member,
		Role:   *data.Role,
	})

	var updateQuery = bson.M{
		"$set": bson.M{
			"members": members,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(t.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// UpdateTeamMemberRole changes the role of a team member
func (t *TeamsType) UpdateTeamMemberRole(id primitive.ObjectID, data UpdateTeamMemberData) (*models.Team, error) {

	var team models.Team
	var members []models.TeamMember

	// Check if member exists
	if _, err := Members.GetMember(*data.Member); err != nil {
		return nil, err
	}

	team1, err := t.GetTeam(id)
	if err != nil {
		return nil, err
	}

	// Check for existent member
	if !team1.HasMember(*data.Member) {
		return nil, errors.New("Member not found")
	}

	members = team1.Members
	for i, s := range members {
		if s.Member == *data.Member {
			members[i].Role = *data.Role
		}
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"members": members,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(t.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// DeleteTeamMember removes a member from a team.
func (t *TeamsType) DeleteTeamMember(id, memberID primitive.ObjectID) (*models.Team, error) {

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

	if err := t.Collection.FindOneAndUpdate(t.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&team); err != nil {
		return nil, err
	}

	return &team, nil
}

// AddMeeting creates and adds a meeting to a team
func (t *TeamsType) AddMeeting(id, meeting primitive.ObjectID) (*models.Team, error){
	
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

	if err = t.Collection.FindOneAndUpdate(t.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

// DeleteTeamMeeting removes a meeting from a team
func (t *TeamsType) DeleteTeamMeeting(teamID, meetingID primitive.ObjectID) (*models.Meeting, error) {

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

	if err = t.Collection.FindOneAndUpdate(t.Context, bson.M{"_id": teamID}, updateQuery, optionsQuery).Decode(&updatedTeam); err != nil {
		return nil, err
	}

	return meeting, nil
}

// PUBLIC METHODS

// GetTeamPublic gets a team by it's id.
func (t *TeamsType) GetTeamPublic(teamID primitive.ObjectID) (*models.TeamPublic, error) {
	var team models.Team

	err := t.Collection.FindOne(t.Context, bson.M{"_id": teamID}).Decode(&team)
	if err != nil {
		return nil, err
	}

	return &models.TeamPublic{
		ID:      team.ID,
		Name:    team.Name,
		Members: team.Members,
	}, nil
}

// GetTeamsPublic gets all teams from an event and returns only public information
func (t *TeamsType) GetTeamsPublic(options GetTeamsOptions) ([]*models.TeamPublic, error) {
	var teams = make([]*models.TeamPublic, 0)
	var event *models.Event
	var err error

	if options.Event != nil {
		event, err = Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}
	} else {
		event, err = Events.GetCurrentEvent()
		if err != nil {
			return nil, err
		}
	}

	for _, s := range event.Teams {
		team, err := t.GetTeamPublic(s)
		if err != nil {
			return nil, err
		}
		if options.Name == nil {
			if options.Member == nil {
				teams = append(teams, team)
			} else if team.HasMember(*options.Member) {
				teams = append(teams, team)
			}
		} else if strings.Contains(strings.ToLower(team.Name), strings.ToLower(*options.Name)) {
			if options.Member == nil {
				teams = append(teams, team)
			} else if team.HasMember(*options.Member) {
				teams = append(teams, team)
			}
		}
	}

	return teams, nil
}
