package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"testing"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	Company = models.Company{Name: "some-name", Description: "some-description", Site: "some-site"}
)

func TestCreateCompany(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newCompany models.Company

	createCompanyData := &mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	b, errMarshal := json.Marshal(createCompanyData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/companies", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newCompany)

	assert.Equal(t, newCompany.Name, Company.Name)
	assert.Equal(t, newCompany.Description, Company.Description)
	assert.Equal(t, newCompany.Site, Company.Site)
}

func TestCreateCompanyInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	type InvalidPayload struct {
		Name string `json:"name"`
	}

	createCompanyData := &InvalidPayload{
		Name: Company.Name,
	}

	b, errMarshal := json.Marshal(createCompanyData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/companies", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetCompanies(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	var companies []models.Company

	res, err := executeRequest("GET", "/companies", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&companies)

	assert.Equal(t, len(companies) == 1, true)
	assert.Equal(t, companies[0].ID, newCompany.ID)
}

func TestAddCompanyParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SinfoID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := &mongodb.AddParticipationData{
		Partner: false,
	}

	b, errMarshal := json.Marshal(apd)
	assert.NilError(t, errMarshal)

	var updatedCompany models.Company

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/participation", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)
	assert.Equal(t, updatedCompany.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedCompany.Participations[0].Member, newMember.ID)

}
