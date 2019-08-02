package router

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"testing"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"gotest.tools/assert"
)

var (
	ID1,_		= primitive.ObjectIDFromHex("1")
	ID2,_		= primitive.ObjectIDFromHex("2")
	ID3,_		= primitive.ObjectIDFromHex("3")
	Team1		= models.Team{ID: ID1, Name: "TEAM1"}
	Team2		= models.Team{ID: ID2, Name: "TEAM2"}
	Team3		= models.Team{ID: ID3, Name: "TEAM3"}
	TeamsArr	= make([]primitive.ObjectID, 0)
)

func containsTeam(teams []models.Team, team models.Team) bool {
	for _, s := range teams {
		if s.ID == team.ID && s.Name == team.Name {
			return true
		}
	}

	return false
}

func TestGetTeamsHandler(t *testing.T) {

	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{"_id": Team1.ID, "name": Team1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{"_id": Team2.ID, "name": Team2.Name}); err != nil {
		log.Fatal(err)
	}

	var teams []models.Team

	res, err := executeRequest("GET", "/teams", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&teams)

	assert.Equal(t, containsTeam(teams, Team1), true)
	assert.Equal(t, containsTeam(teams, Team2), true)
}

func TestGetTeamsByName(t *testing.T) {

	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{"_id": Team1.ID, "name": Team1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{"_id": Team2.ID, "name": Team2.Name}); err != nil {
		log.Fatal(err)
	}

	var teams []models.Team
	var query = "?name=" + url.QueryEscape(Team1.Name)

	res, err := executeRequest("GET", "/teams"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&teams)

	assert.Equal(t, containsTeam(teams, Team1), true)
	assert.Equal(t, containsTeam(teams, Team2), false)
}

func TestGetTeamsByEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event1.ID, "name": Event1.Name, "teams": append(TeamsArr, Team1.ID)}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{
		"_id": Team1.ID, "name": Team1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{
		"_id": Team2.ID, "name": Team2.Name}); err != nil {
			log.Fatal(err)
	}

	var teams []models.Team
	id := primitive.ObjectID.Hex(Team1.ID)
	var query = "?event=" + url.QueryEscape(id)

	res, err := executeRequest("GET", "/teams"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&teams)

	assert.Equal(t, containsTeam(teams, Team1), true)
	assert.Equal(t, containsTeam(teams, Team2), false)
}

func TestGetTeamsBadQuery(t *testing.T) {

	var badQuery1 = "?event=wrong"
	var badQuery2 = "?member=wrong"
	var badQuery3 = "?name=wrong"

	res1, err1 := executeRequest("GET", "/teams"+badQuery1, nil)
	res2, err2 := executeRequest("GET", "/teams"+badQuery2, nil)
	res3, err3 := executeRequest("GET", "/teams"+badQuery3, nil)
	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.NilError(t, err3)

	assert.Equal(t, res1.Code, http.StatusBadRequest)
	assert.Equal(t, res2.Code, http.StatusBadRequest)
	assert.Equal(t, res3.Code, http.StatusBadRequest)
}

func TestGetTeam(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{"_id": Team1.ID, "name": Team1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Teams.Collection.InsertOne(mongodb.Teams.Context, bson.M{"_id": Team2.ID, "name": Team2.Name}); err != nil {
		log.Fatal(err)
	}

	var team1, team2 models.Team

	res1, err1 := executeRequest("GET", fmt.Sprintf("/teams/%v", Event1.ID), nil)
	res2, err2 := executeRequest("GET", fmt.Sprintf("/teams/%v", Event2.ID), nil)
	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.Equal(t, res1.Code, http.StatusOK)
	assert.Equal(t, res2.Code, http.StatusOK)

	json.NewDecoder(res1.Body).Decode(&team1)
	json.NewDecoder(res2.Body).Decode(&team2)

	assert.Equal(t, team1.ID, team1.ID)
	assert.Equal(t, team2.ID, team2.ID)
}

func TestGetTeamsBadID(t *testing.T) {

	res, err := executeRequest("GET", "/temas/bad_ID", nil)
	assert.NilError(t, err)

	assert.Equal(t, res.Code, http.StatusNotFound)
}
