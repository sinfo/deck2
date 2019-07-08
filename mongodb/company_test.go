package mongodb

import (
	"log"
	"os"
	"testing"

	"github.com/globalsign/mgo/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"gotest.tools/assert"
)

func TestMain(m *testing.M) {

	// Database setup
	Setup()
	_, err := Events.Collection.InsertOne(Events.Context, bson.M{"_id": 1, "name": "SINFO1"})

	if err != nil {
		log.Fatal(err)
	}

	_, err = Events.CreateEvent("SINFO2")
	if err != nil {
		log.Fatal(err)
	}

	// Run the test suite
	retCode := m.Run()

	db.Drop(ctx)

	os.Exit(retCode)
}

func TestCreateCompany(t *testing.T) {

	defer Companies.Collection.Drop(Companies.Context)

	var name = "MyCompany Inc"
	var description = "This is a really cool company"
	var site = "mycompany.net"

	newCompany, err := Companies.CreateCompany(name, description, site)

	assert.NilError(t, err)
	assert.Equal(t, newCompany.Name, name)
	assert.Equal(t, newCompany.Description, description)
	assert.Equal(t, newCompany.Site, site)
}

// Test if a participation is added to the current event
func TestAddParticipation(t *testing.T) {

	defer Companies.Collection.Drop(Companies.Context)

	var name = "MyCompany Inc"
	var description = "This is a really cool company"
	var site = "mycompany.net"

	var member = primitive.NewObjectID()
	var partner = true

	company, _ := Companies.CreateCompany(name, description, site)
	currentEvent, _ := Events.GetCurrentEvent()

	updatedCompany, err := Companies.AddParticipation(company.ID, member, partner)

	assert.NilError(t, err)
	assert.Equal(t, updatedCompany.Name, name)
	assert.Equal(t, updatedCompany.Description, description)
	assert.Equal(t, updatedCompany.Site, site)
	assert.Equal(t, len(updatedCompany.Participations), 1)

	var found = false
	for _, p := range updatedCompany.Participations {
		if p.Member == member && p.Partner == partner && p.Event == currentEvent.ID {
			found = true
			break
		}
	}

	assert.Equal(t, found, true)
}
