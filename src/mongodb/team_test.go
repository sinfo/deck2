package mongodb

import (
	"testing"

	"gotest.tools/assert"
)


func TestCreateTeam(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

	createTeamData := CreateTeamData{
		Name:        "Mega-DevTeam",
	}

	newTeam, err := Teams.CreateTeam(createTeamData)

	assert.NilError(t, err)
	assert.Equal(t, newTeam.Name, createTeamData.Name)
}