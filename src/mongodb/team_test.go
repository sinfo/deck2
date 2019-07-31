package mongodb

import (
	"testing"

	"gotest.tools/assert"

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

func TestGetTeam (t *testing.T) {

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