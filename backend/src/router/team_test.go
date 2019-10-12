package router

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"testing"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"gotest.tools/assert"
)

var (
	Team1      *models.Team
	Team2      *models.Team
	TeamEvent2 *models.Event
	TeamsArr   = make([]primitive.ObjectID, 0)
)

func containsTeam(teams []models.Team, team *models.Team) bool {
	for _, s := range teams {
		if s.ID == team.ID && s.Name == team.Name {
			return true
		}
	}

	return false
}

func containsTeamPublic(teams []models.TeamPublic, team *models.Team) bool {
	for _, s := range teams {
		if s.ID == team.ID && s.Name == team.Name {
			return true
		}
	}

	return false
}

func setupTest() {

	ctx := context.Background()

	_, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": 1, "name": "SINFO1"})

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
	ctx := context.Background()

	setupTest()

	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM2"})
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
	ctx := context.Background()

	setupTest()

	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM2"})
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

	res, err = executeRequest("GET", "/teams?name=wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&teams)

	assert.Equal(t, len(teams), 0)
}

func TestGetTeamsByEvent(t *testing.T) {
	ctx := context.Background()

	setupTest()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: "TestEvent"}); err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM2"})
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
	ctx := context.Background()

	setupTest()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM2"})
	if err != nil {
		log.Fatal(err)
	}

	var team1, team2 models.Team

	res1, err1 := executeRequest("GET", "/teams/"+Team1.ID.Hex(), nil)
	res2, err2 := executeRequest("GET", "/teams/"+Team2.ID.Hex(), nil)

	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.Equal(t, res1.Code, http.StatusOK)
	assert.Equal(t, res2.Code, http.StatusOK)

	json.NewDecoder(res1.Body).Decode(&team1)
	json.NewDecoder(res2.Body).Decode(&team2)

	assert.Equal(t, team1.ID, team1.ID)
	assert.Equal(t, team2.ID, team2.ID)
}

func TestGetTeamBadID(t *testing.T) {

	res, err := executeRequest("GET", "/teams/bad_ID", nil)
	assert.NilError(t, err)

	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestDeleteTeam(t *testing.T) {
	ctx := context.Background()

	setupTest()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM2"})
	if err != nil {
		log.Fatal(err)
	}

	var team1, team2 models.Team

	res1, err1 := executeRequest("DELETE", "/teams/"+Team1.ID.Hex(), nil)
	res2, err2 := executeRequest("DELETE", "/teams/"+Team2.ID.Hex(), nil)

	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.Equal(t, res1.Code, http.StatusOK)
	assert.Equal(t, res2.Code, http.StatusOK)

	json.NewDecoder(res1.Body).Decode(&team1)
	json.NewDecoder(res2.Body).Decode(&team2)

	assert.Equal(t, team1.ID, team1.ID)
	assert.Equal(t, team2.ID, team2.ID)

	res1, err1 = executeRequest("GET", "/teams/"+Team1.ID.Hex(), nil)
	res2, err2 = executeRequest("GET", "/teams/"+Team2.ID.Hex(), nil)

	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.Equal(t, res1.Code, http.StatusNotFound)
	assert.Equal(t, res2.Code, http.StatusNotFound)
}

func TestDeleteTeamsBadID(t *testing.T) {

	res, err := executeRequest("DELETE", "/teams/bad_ID", nil)
	assert.NilError(t, err)

	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestCreateTeam(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)

	setupTest()

	Team1 = &models.Team{Name: "TEAM1"}

	var newTeam models.Team
	var team2 models.Team

	createTeamData := &mongodb.CreateEventData{Name: Team1.Name}

	b, errMarshal := json.Marshal(createTeamData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/teams", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newTeam)

	assert.Equal(t, newTeam.Name, Team1.Name)

	res, err = executeRequest("GET", "/teams/"+newTeam.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&team2)

	assert.Equal(t, team2.Name, newTeam.Name)
	assert.Equal(t, team2.ID, newTeam.ID)
}

func TestUpdateTeam(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	var updatedTeam models.Team

	var name = "TEAM2"
	utd := &mongodb.CreateTeamData{Name: name}

	b, errMarshal := json.Marshal(utd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/teams/"+Team1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedTeam)

	assert.Equal(t, updatedTeam.ID, Team1.ID)
	assert.Equal(t, updatedTeam.Name, name)
}

func TestUpdateTeamBadPayload(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	var name = ""
	utd := &mongodb.CreateTeamData{Name: name}

	b, errMarshal := json.Marshal(utd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/teams/"+Team1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateTeamBadID(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	var name = "TEAM2"
	utd := &mongodb.CreateTeamData{Name: name}

	b, errMarshal := json.Marshal(utd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/teams/wrong", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	team, err := mongodb.Teams.GetTeam(Team1.ID)
	assert.NilError(t, err)
	assert.Equal(t, team.Name, Team1.Name)

}

func TestAddTeamMember(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	setupTest()

	var team models.Team

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid: "ist123456",
	}

	member, err := mongodb.Members.CreateMember(cmd)

	utmd := &mongodb.CreateTeamMemberData{
		Member: member.ID,
		Role:   role,
	}

	b, errMarshal := json.Marshal(utmd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&team)
	assert.Equal(t, len(team.Members), 1)
	assert.Equal(t, team.Members[0].Member, member.ID)

	// Test Duplicate member on team

	utmd = &mongodb.CreateTeamMemberData{
		Member: member.ID,
		Role:   role,
	}

	b, errMarshal = json.Marshal(utmd)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	// Test wrong member id

	randID := primitive.NewObjectID()

	utmd = &mongodb.CreateTeamMemberData{
		Member: randID,
		Role:   role,
	}

	b, errMarshal = json.Marshal(utmd)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

}

func TestUpdateTeamMemberRole(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	setupTest()

	var team models.Team

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid: "ist123456",
	}

	member, err := mongodb.Members.CreateMember(cmd)

	var role = models.RoleMember

	ctmd := &mongodb.CreateTeamMemberData{
		Member: member.ID,
		Role:   role,
	}

	Team1, err = mongodb.Teams.AddTeamMember(Team1.ID, *ctmd)
	assert.NilError(t, err)

	var updatedRole = models.RoleTeamLeader

	utmd := &mongodb.UpdateTeamMemberData{
		Role: &updatedRole,
	}

	b, errMarshal := json.Marshal(utmd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/teams/"+Team1.ID.Hex()+"/members/"+member.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&team)
	assert.Equal(t, len(team.Members), 1)
	assert.Equal(t, team.Members[0].Member, member.ID)
	assert.Equal(t, team.Members[0].Role, updatedRole)

	// Test wrong member id

	utmd = &mongodb.UpdateTeamMemberData{
		Role: &updatedRole,
	}

	b, errMarshal = json.Marshal(utmd)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("PUT", "/teams/"+Team1.ID.Hex()+"/members/wrong", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	// Test not found team

	res, err = executeRequest("PUT", "/teams/wrong/members/wrong", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestDeleteTeamMember(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid: "ist123456",
	}

	member, err := mongodb.Members.CreateMember(cmd)

	var role = models.RoleMember

	ctmd := &mongodb.CreateTeamMemberData{
		Member: member.ID,
		Role:   role,
	}

	Team1, err = mongodb.Teams.AddTeamMember(Team1.ID, *ctmd)
	assert.NilError(t, err)

	var deletedTeam models.Team

	res, err := executeRequest("DELETE", "/teams/"+Team1.ID.Hex()+"/members/"+member.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&deletedTeam)
	assert.Equal(t, deletedTeam.ID, Team1.ID)
	assert.Equal(t, len(deletedTeam.Members), 0)

	// Test wrong member id

	ctmd = &mongodb.CreateTeamMemberData{
		Member: member.ID,
		Role:   role,
	}

	Team1, err = mongodb.Teams.AddTeamMember(Team1.ID, *ctmd)
	assert.NilError(t, err)

	randID := primitive.NewObjectID()

	res, err = executeRequest("DELETE", "/teams/"+Team1.ID.Hex()+"/members/"+randID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	// Test not found team

	res, err = executeRequest("DELETE", "/teams/wrong/members/"+randID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddMeeting(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	var team models.Team

	b, errMarshall := json.Marshal(Meeting1Data)
	assert.NilError(t, errMarshall)

	res, err := executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&team)

	assert.Equal(t, team.ID, Team1.ID)
	assert.Equal(t, len(team.Meetings), 1)

	meeting, err := mongodb.Meetings.GetMeeting(team.Meetings[0])
	assert.NilError(t, err)

	assert.Equal(t, meeting.Place, *Meeting1Data.Place)

	// Bad ID

	res, err = executeRequest("POST", "/teams/wrong/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

}

func TestAddMeetingBadPayload(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	var BadData1 = mongodb.CreateMeetingData{
		End:   &TimeAfter,
		Place: &Place1,
	}
	var BadData2 = mongodb.CreateMeetingData{
		Begin: &TimeBefore,
		Place: &Place1,
	}
	var BadData3 = mongodb.CreateMeetingData{
		Begin: &TimeBefore,
		End:   &TimeAfter,
	}
	var BadData4 = mongodb.CreateMeetingData{
		Begin: &TimeAfter,
		End:   &TimeBefore,
		Place: &Place1,
	}

	b, errMarshal := json.Marshal(BadData1)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	b, errMarshal = json.Marshal(BadData2)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	b, errMarshal = json.Marshal(BadData3)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	b, errMarshal = json.Marshal(BadData4)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/teams/"+Team1.ID.Hex()+"/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestDeleteTeamMeeting(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	if err != nil {
		log.Fatal(err)
	}

	Team1, err = mongodb.Teams.AddMeeting(Team1.ID, Meeting1.ID)
	if err != nil {
		log.Fatal(err)
	}

	Meeting1, err = mongodb.Meetings.GetMeeting(Team1.Meetings[0])
	if err != nil {
		log.Fatal(err)
	}

	var meeting models.Meeting

	res, err := executeRequest("DELETE", "/teams/"+Team1.ID.Hex()+"/meetings/"+Meeting1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meeting)

	assert.Equal(t, meeting.ID, Meeting1.ID)
	assert.Equal(t, meeting.Place, Meeting1.Place)
}

func TestDeleteTeamMeetingBad(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	setupTest()

	Team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	if err != nil {
		log.Fatal(err)
	}

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	if err != nil {
		log.Fatal(err)
	}

	Team1, err = mongodb.Teams.AddMeeting(Team1.ID, Meeting1.ID)
	if err != nil {
		log.Fatal(err)
	}

	Meeting1, err = mongodb.Meetings.GetMeeting(Team1.Meetings[0])
	if err != nil {
		log.Fatal(err)
	}

	Meeting2, err = mongodb.Meetings.CreateMeeting(Meeting2Data)
	if err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("DELETE", "/teams/"+Team1.ID.Hex()+"/meetings/"+Meeting2.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	res, err = executeRequest("DELETE", "/teams/wrong/meetings/"+Meeting1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	res, err = executeRequest("DELETE", "/teams/"+Team1.ID.Hex()+"/meetings/wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

}
