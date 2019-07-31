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