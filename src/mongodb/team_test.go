package mongodb

import (
	"testing"

	"gotest.tools/assert"
	is"gotest.tools/assert/cmp"
)


func TestCreateTeam(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

	createTeamData := CreateTeamData{
		Name:        "team1",
	}

	newTeam, err := Teams.CreateTeam(createTeamData)

	assert.NilError(t, err)
	assert.Equal(t, newTeam.Name, createTeamData.Name)

	event, err := Events.GetCurrentEvent()

	assert.NilError(t,err)
	assert.Equal(t, len(event.Teams), 1)
}

func TestGetTeam(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

	createTeamData :=CreateTeamData{
		Name:	"team2",
	}
	newTeam, _ := Teams.CreateTeam(createTeamData)

	sameTeam, err := Teams.GetTeam(newTeam.ID)

	assert.NilError(t, err)
	assert.Equal(t, newTeam.ID, sameTeam.ID)
}

func TestDeleteTeam(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

	createTeamData :=CreateTeamData{
		Name:	"team2",
	}
	team1, _ := Teams.CreateTeam(createTeamData)

	team2, err := Teams.DeleteTeam(team1.ID)

	assert.NilError(t, err)
	assert.Equal(t, team1.ID, team2.ID)

	team3, err := Teams.GetTeam(team2.ID)
	
	assert.Assert(t, is.Nil(team3))
}

func TestGetTeams(t *testing.T) {
	
	SetupTest()
	defer db.Drop(ctx)
	
	CreateTeamData1 := CreateTeamData{
		Name: "team1",
	}
	CreateTeamData2 := CreateTeamData{
		Name: "team2",
	}
	team1, _ := Teams.CreateTeam(CreateTeamData1)
	team2, _ := Teams.CreateTeam(CreateTeamData2)
	name := "1"
	event,_ := Events.GetCurrentEvent()
	id := event.ID
	t.Log(id)
	t.Log(event)

	gto0 := GetTeamsOptions{
		Name: nil,
		Event: nil,
		Member: nil,
	}
	teams, err := Teams.GetTeams(gto0)
	assert.NilError(t, err)
	assert.Equal(t, len(teams), 2)

	gto1 := GetTeamsOptions{
		Name: &name,
		Event: nil,
		Member: nil,
	}
	teams,err = Teams.GetTeams(gto1)
	assert.NilError(t, err)
	assert.Equal(t, len(teams), 1)
	assert.Equal(t, teams[0].ID, team1.ID )

	gto2 := GetTeamsOptions{
		Name: nil,
		Event: &(id),
		Member: nil,
	}
	teams, err = Teams.GetTeams(gto2)
	assert.NilError(t, err)
	assert.Equal(t, len(teams), 2)
	assert.Equal(t, teams[1].ID, team2.ID)
}