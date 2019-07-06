package mongodb

import (
	"os"
	"testing"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"gotest.tools/assert"
)

func TestMain(m *testing.M) {
	// The tempdir is created so MongoDB has a location to store its files.
	// Contents are wiped once the server stops
	//tempDir, _ := ioutil.TempDir("", "testing")
	//Server.SetPath(tempDir)

	Setup()

	// Run the test suite
	retCode := m.Run()

	os.Exit(retCode)
}

func TestCreateCompany(t *testing.T) {

	defer companies.Drop(ctx)

	var name = "MyCompany Inc"
	var description = "This is a really cool company"
	var site = "mycompany.net"

	newCompany, err := CreateCompany(name, description, site)

	assert.NilError(t, err)
	assert.Equal(t, newCompany.Name, name)
	assert.Equal(t, newCompany.Description, description)
	assert.Equal(t, newCompany.Site, site)
}

func TestAddParticipation(t *testing.T) {

	//defer companies.Drop(ctx)

	var name = "MyCompany Inc"
	var description = "This is a really cool company"
	var site = "mycompany.net"

	var member = primitive.NewObjectID()
	var partner = true

	company, _ := CreateCompany(name, description, site)

	updatedCompany, err := AddParticipation(company.ID, member, partner)

	assert.NilError(t, err)
	assert.Equal(t, updatedCompany.Name, name)
	assert.Equal(t, updatedCompany.Description, description)
	assert.Equal(t, updatedCompany.Site, site)

	var found = false

	for _, p := range updatedCompany.Participations {
		if p.Member == member && p.Partner == partner {
			found = true
			break
		}
	}

	assert.Equal(t, found, true)
}
