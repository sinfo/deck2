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

type TeamsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type CreateTeamData struct {
	Name        string `json:"name"`
}

type GetTeamsOptions struct {
	Name		*string 
	Event		*int
	Member		*primitive.ObjectID
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

// CreateTeam creates a new team and adds it to the current event
func (t *TeamsType) CreateTeam(data CreateTeamData) (*models.Team, error) {

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)
	var updatedEvent models.Event

	insertResult, err := t.Collection.InsertOne(t.Context, bson.M{
		"name":        data.Name,
	})
	if err != nil {
		return nil, err
	}

	newTeam, err := t.GetTeam(insertResult.InsertedID.(primitive.ObjectID))
	if err != nil {
		return nil, err
	}
	
	event, err := Events.GetCurrentEvent()
	if err != nil{
		return nil, err
	}
	
	teams:= append(event.Teams,newTeam.ID )

	var updateQuery = bson.M{
		"$set": bson.M{
			"teams":  teams,
		},
	}

	if err = Events.Collection.FindOneAndUpdate(Events.Context, bson.M{"_id": event.ID}, updateQuery, optionsQuery).Decode(&updatedEvent); err != nil {
		log.Println("Error updating events teams",err)
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
		event, err  = Events.GetEvent(*options.Event)
		if err != nil{
			return nil, err
		}
	} else{
		event, err = Events.GetCurrentEvent(); 
		if err != nil {
			return nil, err
		}
	}

	for _,s := range event.Teams {
		team, err := t.GetTeam(s);
		if err != nil {
			return nil, err
		}
		if options.Name == nil{
			if options.Member == nil{
				teams = append(teams, team)
			}else if team.HasMember(*options.Member){
				teams = append(teams, team)
			}
		} else if strings.Contains(strings.ToLower(team.Name),strings.ToLower(*options.Name)){
			if options.Member == nil{
				teams = append(teams, team)
			}else if team.HasMember(*options.Member){
				teams = append(teams, team)
			}
		}
	}

	return teams, nil
}


// DeleteTeam deletes a team by its ID.
func (t* TeamsType) DeleteTeam(teamID primitive.ObjectID) (*models.Team, error) {

	var team models.Team

	err := t.Collection.FindOneAndDelete(t.Context, bson.M{"_id": teamID}).Decode(&team)
	if err != nil {
		return nil, err
	}

	return &team, nil
}

// UpdateTeam updates the team name.
func (t* TeamsType) UpdateTeam(teamID primitive.ObjectID, data CreateTeamData) (*models.Team, error){

	var team models.Team

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":  data.Name,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := t.Collection.FindOneAndUpdate(t.Context, bson.M{"_id": teamID}, updateQuery, optionsQuery).Decode(&team); err != nil{
		return nil, err
	}

	return &team, nil
}