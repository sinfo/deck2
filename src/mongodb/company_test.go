package mongodb

import (
	"log"
	"os"
	"testing"

	"github.com/globalsign/mgo/bson"
	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"gotest.tools/assert"
)

func SetupTest() {
	_, err := Events.CreateEvent("SINFO2")
	if err != nil {
		log.Fatal(err)
	}
}

func TestMain(m *testing.M) {

	// Database setup
	InitializeDatabase()
	_, err := Events.Collection.InsertOne(Events.Context, bson.M{"_id": 1, "name": "SINFO1"})

	if err != nil {
		log.Fatal(err)
	}

	// Run the test suite
	retCode := m.Run()

	db.Drop(ctx)

	os.Exit(retCode)
}

func TestCreateCompany(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

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

	SetupTest()
	defer db.Drop(ctx)

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

func TestRemoveParticipation(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

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

	Companies.AddParticipation(company.ID, addParticipationData)
	updatedCompany, err := Companies.RemoveParticipation(company.ID)

	assert.NilError(t, err)
	assert.Equal(t, updatedCompany.Name, createCompanyData.Name)
	assert.Equal(t, updatedCompany.Description, createCompanyData.Description)
	assert.Equal(t, updatedCompany.Site, createCompanyData.Site)
	assert.Equal(t, len(updatedCompany.Participations), 0)
}

func TestUpdateCompany(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

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

// Extensive test of the Status' state machine
func TestStepStatusCompany(t *testing.T) {

	SetupTest()
	defer db.Drop(ctx)

	createCompanyData := CreateCompanyData{
		Name:        "MyCompany Inc",
		Description: "This is a really cool company",
		Site:        "mycompany.net",
	}

	addParticipationData := AddParticipationData{
		MemberID: primitive.NewObjectID(),
		Partner:  false,
	}

	company, _ := Companies.CreateCompany(createCompanyData)

	c0, err0 := Companies.AddParticipation(company.ID, addParticipationData) // SUGGESTED
	assert.NilError(t, err0)
	assert.Equal(t, c0.Participations[0].Status, models.Suggested)

	Events.CreateEvent("event2")
	c1, err1 := Companies.AddParticipation(company.ID, addParticipationData) // SUGGESTED
	c2, err2 := Companies.StepStatus(company.ID, 1)                          // SELECTED
	c3, err3 := Companies.StepStatus(company.ID, 1)                          // CONTACTED
	c4, err4 := Companies.StepStatus(company.ID, 1)                          // IN_CONVERSATIONS
	c5, err5 := Companies.StepStatus(company.ID, 1)                          // ACCEPTED
	c6, err6 := Companies.StepStatus(company.ID, 1)                          // ANNOUNCED

	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.NilError(t, err3)
	assert.NilError(t, err4)
	assert.NilError(t, err5)
	assert.NilError(t, err6)

	assert.Equal(t, c1.Participations[1].Status, models.Suggested)
	assert.Equal(t, c2.Participations[1].Status, models.Selected)
	assert.Equal(t, c3.Participations[1].Status, models.Contacted)
	assert.Equal(t, c4.Participations[1].Status, models.InConversations)
	assert.Equal(t, c5.Participations[1].Status, models.Accepted)
	assert.Equal(t, c6.Participations[1].Status, models.Announced)

	Events.CreateEvent("event3")
	c7, err7 := Companies.AddParticipation(company.ID, addParticipationData) // SUGGESTED
	c8, err8 := Companies.StepStatus(company.ID, 2)                          // ON_HOLD
	c9, err9 := Companies.StepStatus(company.ID, 1)                          // SELECTED

	assert.NilError(t, err7)
	assert.NilError(t, err8)
	assert.NilError(t, err9)

	assert.Equal(t, c7.Participations[2].Status, models.Suggested)
	assert.Equal(t, c8.Participations[2].Status, models.OnHold)
	assert.Equal(t, c9.Participations[2].Status, models.Selected)

	Events.CreateEvent("event4")
	c10, err10 := Companies.AddParticipation(company.ID, addParticipationData) // SUGGESTED
	c11, err11 := Companies.StepStatus(company.ID, 1)                          // SELECTED
	c12, err12 := Companies.StepStatus(company.ID, 1)                          // CONTACTED
	c13, err13 := Companies.StepStatus(company.ID, 2)                          // REJECTED

	assert.NilError(t, err10)
	assert.NilError(t, err11)
	assert.NilError(t, err12)
	assert.NilError(t, err13)

	assert.Equal(t, c10.Participations[3].Status, models.Suggested)
	assert.Equal(t, c11.Participations[3].Status, models.Selected)
	assert.Equal(t, c12.Participations[3].Status, models.Contacted)
	assert.Equal(t, c13.Participations[3].Status, models.Rejected)

	Events.CreateEvent("event5")
	c14, err14 := Companies.AddParticipation(company.ID, addParticipationData) // SUGGESTED
	c15, err15 := Companies.StepStatus(company.ID, 1)                          // SELECTED
	c16, err16 := Companies.StepStatus(company.ID, 1)                          // CONTACTED
	c17, err17 := Companies.StepStatus(company.ID, 3)                          // GIVEN_UP

	assert.NilError(t, err14)
	assert.NilError(t, err15)
	assert.NilError(t, err16)
	assert.NilError(t, err17)

	assert.Equal(t, c14.Participations[4].Status, models.Suggested)
	assert.Equal(t, c15.Participations[4].Status, models.Selected)
	assert.Equal(t, c16.Participations[4].Status, models.Contacted)
	assert.Equal(t, c17.Participations[4].Status, models.GivenUp)

	Events.CreateEvent("event6")
	c18, err18 := Companies.AddParticipation(company.ID, addParticipationData) // SUGGESTED
	c19, err19 := Companies.StepStatus(company.ID, 1)                          // SELECTED
	c20, err20 := Companies.StepStatus(company.ID, 1)                          // CONTACTED
	c21, err21 := Companies.StepStatus(company.ID, 1)                          // IN_CONVERSATIONS
	c22, err22 := Companies.StepStatus(company.ID, 2)                          // REJECTED

	assert.NilError(t, err18)
	assert.NilError(t, err19)
	assert.NilError(t, err20)
	assert.NilError(t, err21)
	assert.NilError(t, err22)

	assert.Equal(t, c18.Participations[5].Status, models.Suggested)
	assert.Equal(t, c19.Participations[5].Status, models.Selected)
	assert.Equal(t, c20.Participations[5].Status, models.Contacted)
	assert.Equal(t, c21.Participations[5].Status, models.InConversations)
	assert.Equal(t, c22.Participations[5].Status, models.Rejected)

	Events.CreateEvent("event7")
	c23, err23 := Companies.AddParticipation(company.ID, addParticipationData) // SUGGESTED
	c24, err24 := Companies.StepStatus(company.ID, 1)                          // SELECTED
	c25, err25 := Companies.StepStatus(company.ID, 1)                          // CONTACTED
	c26, err26 := Companies.StepStatus(company.ID, 1)                          // IN_CONVERSATIONS
	c27, err27 := Companies.StepStatus(company.ID, 3)                          // GIVEN_UP

	assert.NilError(t, err23)
	assert.NilError(t, err24)
	assert.NilError(t, err25)
	assert.NilError(t, err26)
	assert.NilError(t, err27)

	assert.Equal(t, c23.Participations[6].Status, models.Suggested)
	assert.Equal(t, c24.Participations[6].Status, models.Selected)
	assert.Equal(t, c25.Participations[6].Status, models.Contacted)
	assert.Equal(t, c26.Participations[6].Status, models.InConversations)
	assert.Equal(t, c27.Participations[6].Status, models.GivenUp)

}
