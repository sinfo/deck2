package mongodb

import (
	"log"
	"os"
	"testing"

	"github.com/globalsign/mgo/bson"
	"github.com/sinfo/deck2/models"
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

	createCompanyData := CreateCompanyData{
		Name:        "MyCompany Inc",
		Description: "This is a really cool company",
		Site:        "mycompany.net",
	}

	newCompany, err := Companies.CreateCompany(createCompanyData)

	assert.NilError(t, err)
	assert.Equal(t, newCompany.Name, createCompanyData.Name)
	assert.Equal(t, newCompany.Description, createCompanyData.Description)
	assert.Equal(t, newCompany.Site, createCompanyData.Site)
}

// Test if a participation is added to the current event
func TestAddParticipation(t *testing.T) {

	defer Companies.Collection.Drop(Companies.Context)

	createCompanyData := CreateCompanyData{
		Name:        "MyCompany Inc",
		Description: "This is a really cool company",
		Site:        "mycompany.net",
	}

	addParticipationData := AddParticipationData{
		MemberID: primitive.NewObjectID(),
		Partner:  true,
	}

	company, _ := Companies.CreateCompany(createCompanyData)
	currentEvent, _ := Events.GetCurrentEvent()

	updatedCompany, err := Companies.AddParticipation(company.ID, addParticipationData)

	assert.NilError(t, err)
	assert.Equal(t, updatedCompany.Name, createCompanyData.Name)
	assert.Equal(t, updatedCompany.Description, createCompanyData.Description)
	assert.Equal(t, updatedCompany.Site, createCompanyData.Site)
	assert.Equal(t, len(updatedCompany.Participations), 1)

	var found = false
	for _, p := range updatedCompany.Participations {
		if p.Member == addParticipationData.MemberID && p.Partner == addParticipationData.Partner && p.Event == currentEvent.ID {
			found = true
			break
		}
	}

	assert.Equal(t, found, true)
}

func TestUpdateCompany(t *testing.T) {

	defer Companies.Collection.Drop(Companies.Context)

	createCompanyData := CreateCompanyData{
		Name:        "MyCompany Inc",
		Description: "This is a really cool company",
		Site:        "mycompany.net",
	}

	updateCompanyData := UpdateCompanyData{
		Name:        "NOT MyCompany Inc",
		Description: "NOT This is a really cool company",
		Site:        "NOT mycompany.net",
		BillingInfo: models.CompanyBillingInfo{
			Name:    "some-billing-name",
			Address: "some-billing-address",
			TIN:     "some-billing-tin",
		},
	}

	company, _ := Companies.CreateCompany(createCompanyData)
	updatedCompany, err := Companies.UpdateCompany(company.ID, updateCompanyData)

	assert.NilError(t, err)
	assert.Equal(t, updatedCompany.ID, company.ID)
	assert.Equal(t, updatedCompany.Name, updateCompanyData.Name)
	assert.Equal(t, updatedCompany.Site, updateCompanyData.Site)
	assert.Equal(t, updatedCompany.Description, updateCompanyData.Description)
	assert.Equal(t, updatedCompany.BillingInfo.Name, updateCompanyData.BillingInfo.Name)
	assert.Equal(t, updatedCompany.BillingInfo.Address, updateCompanyData.BillingInfo.Address)
	assert.Equal(t, updatedCompany.BillingInfo.TIN, updateCompanyData.BillingInfo.TIN)

}
