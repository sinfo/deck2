package router

import (
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"testing"
	"strconv"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"gotest.tools/assert"
)

var (
	Team1		*models.Team
	Team2		*models.Team
	TeamEvent2	*models.Event
	TeamsArr	= make([]primitive.ObjectID, 0)
)

func containsTeam(teams []models.Team, team *models.Team) bool {
	for _, s := range teams {
		if s.ID == team.ID && s.Name == team.Name {
			return true
		}
	}

	return false
}

func setupTest(){

	_, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": 1, "name": "SINFO1"})

	if err != nil {
		log.Fatal(err)
	}
	ced := mongodb.CreateEventData{
		Name: "SINFO2",
	}
	TeamEvent2, err = mongodb.Events.CreateEvent(ced)
	if err != nil {
		log.Fatal(err)
	}
}

func TestGetTeams(t *testing.T) {

	setupTest()

	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM2"})
	if err != nil {
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

	setupTest()

	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM2"})
	if err != nil {
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

	res, err = executeRequest("GET", "/teams?name=wrong",nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code,http.StatusOK)

	json.NewDecoder(res.Body).Decode(&teams)

	assert.Equal(t, len(teams),0)
}

func TestGetTeamsByEvent(t *testing.T) {

	setupTest()

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: "TestEvent"}); err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM2"})
	if err != nil {
		log.Fatal(err)
	}


	var teams []models.Team
	id := strconv.Itoa(TeamEvent2.ID)
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

	res1, err1 := executeRequest("GET", "/teams"+badQuery1, nil)
	res2, err2 := executeRequest("GET", "/teams"+badQuery2, nil)
	assert.NilError(t, err1)
	assert.NilError(t, err2)

	assert.Equal(t, res1.Code, http.StatusBadRequest)
	assert.Equal(t, res2.Code, http.StatusBadRequest)
}

func TestGetTeam(t *testing.T) {

	setupTest()

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name:"TEAM2"})
	if err != nil {
		log.Fatal(err)
	}

	var team1, team2 models.Team

	res1, err1 := executeRequest("GET", "/teams/"+ Team1.ID.Hex(), nil)
	res2, err2 := executeRequest("GET", "/teams/"+ Team2.ID.Hex(), nil)
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
