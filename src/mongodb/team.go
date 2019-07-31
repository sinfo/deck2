package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type TeamsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type CreateTeamData struct {
	Name        string `json:"name"`
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

// CreateTeam creates a new team and saves it to the database
func (t *TeamsType) CreateTeam(data CreateTeamData) (*models.Team, error) {

	insertResult, err := t.Collection.InsertOne(t.Context, bson.M{
		"name":        data.Name,
	})

	if err != nil {
		return nil, err
	}

	newTeam, err := t.GetTeam(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created team", err)
		return nil, err
	}

	return newTeam, nil
}

// GetTeams gets all teams specified with a query
func (t *TeamsType) GetTeams(query bson.M) ([]*models.Team, error) {
	var teams = make([]*models.Team, 0)

	cur, err := t.Collection.Find(t.Context, query)
	if err != nil {
		return nil, err
	}

	for cur.Next(t.Context) {

		// create a value into which the single document can be decoded
		var t models.Team
		err := cur.Decode(&t)
		if err != nil {
			return nil, err
		}

		teams = append(teams, &t)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(t.Context)

	return teams, nil
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

// DeleteTeam deletes a team by its ID.
func (t* TeamsType) DeleteTeam(teamID primitive.ObjectID) (*models.Team, error) {
	var team models.Team

	err := t.Collection.FindOneAndDelete(t.Context, bson.M{"_id": teamID}).Decode(&team)
	if err != nil {
		return nil, err
	}

	return &team, nil
}