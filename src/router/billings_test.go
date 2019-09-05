package router

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
	"bytes"
	"strconv"
	"encoding/json"
	"net/http"
	"net/url"
	"testing"
	"time"
	"log"
	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"gotest.tools/assert"
	"go.mongodb.org/mongo-driver/bson"
)

var (
	Billing1	*models.Billing
	Billing2	*models.Billing
	FALSE = false
	TRUE = true
	BillingStatus = mongodb.CreateStatusData{
		Invoice: &FALSE,
		Receipt: &FALSE,
		ProForma: &FALSE,
		Paid: &FALSE,
	}
	Billing1Value = 500
	Billing1Invoice = "123"
	Billing1Emission = time.Now()
	Billing1Employer = primitive.NewObjectID()
	Billing1Notes = "Some notes"
	Billing1Data = mongodb.CreateBillingData{
		Status: &BillingStatus,
		Event: &Event1.ID,
		Value: &Billing1Value,
		InvoiceNumber: &Billing1Invoice,
		Emission: &Billing1Emission,
		Notes: &Billing1Notes,
	}
	Billing2Value = 800
	Billing2Invoice = "321"
	Billing2Emission = Billing1Emission.Add(time.Hour * 20)
	Billing2Employer = primitive.NewObjectID()
	Billing2Notes = "Some notes2"
	Billing2Data = mongodb.CreateBillingData{
		Status: &BillingStatus,
		Event: &Event2.ID,
		Value: &Billing2Value,
		InvoiceNumber: &Billing2Invoice,
		Emission: &Billing2Emission,
		Notes: &Billing2Notes,
	}
)

func TestGetBillings(t *testing.T){
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Billings.Collection.Drop(mongodb.Billings.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	company, err := mongodb.Companies.CreateCompany(mongodb.CreateCompanyData{
		Name: &Company.Name,
		Description: &Company.Description,
		Site: &Company.Site,
		
	})
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role1 = models.RoleAdmin
	var role2 = models.RoleMember

	cmd1 := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID1",
	}

	cmd2 := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID2",
	}

	newMember1, err := mongodb.Members.CreateMember(cmd1)
	assert.NilError(t, err)

	newMember2, err := mongodb.Members.CreateMember(cmd2)
	assert.NilError(t, err)

	utmd1 := mongodb.UpdateTeamMemberData{
		Member: &newMember1.ID,
		Role:   &role1,
	}

	utmd2 := mongodb.UpdateTeamMemberData{
		Member: &newMember2.ID,
		Role:   &role2,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd1)
	assert.NilError(t, err)

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd2)
	assert.NilError(t, err)

	Billing1Data.Company = &company.ID
	Billing1Data.Visible = &TRUE

	Billing1, err := mongodb.Billings.CreateBilling(Billing1Data)
	assert.NilError(t, err)

	Billing2, err = mongodb.Billings.CreateBilling(Billing2Data)
	assert.NilError(t, err)

	Billing1Data.Company = nil

	var billings []*models.Billing

	credentialsAdmin, err := mongodb.Members.GetMemberAuthCredentials(newMember1.SINFOID)
	assert.NilError(t, err)

	tokenAdmin, err := auth.SignJWT(*credentialsAdmin)
	assert.NilError(t, err)

	credentialsMember, err := mongodb.Members.GetMemberAuthCredentials(newMember2.SINFOID)
	assert.NilError(t, err)

	tokenMember, err := auth.SignJWT(*credentialsMember)
	assert.NilError(t, err)

	// No Query, admin

	config.Authentication = true
	res, err := executeAuthenticatedRequest("GET", "/billings", nil, *tokenAdmin)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 2)

	// No Query, member

	config.Authentication = true
	res, err = executeAuthenticatedRequest("GET", "/billings", nil, *tokenMember)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)

	// After on query

	var query = "?after="+ url.QueryEscape(TimeAfter.Format(time.RFC3339))

	config.Authentication = true
	res, err = executeAuthenticatedRequest("GET", "/billings"+query, nil, *tokenAdmin)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing2.ID)

	// Before on query

	query = "?before="+url.QueryEscape(TimeAfter.Format(time.RFC3339))

	config.Authentication = true
	res, err = executeAuthenticatedRequest("GET", "/billings"+query, nil, *tokenAdmin)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)

	// ValueGreaterThan on query

	query = "?valueGreaterThan="+url.QueryEscape(strconv.Itoa(600))

	config.Authentication = true
	res, err = executeAuthenticatedRequest("GET", "/billings"+query, nil, *tokenAdmin)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing2.ID)

	// ValueLessThan on query

	query = "?valueLessThan="+url.QueryEscape(strconv.Itoa(600))

	config.Authentication = true
	res, err = executeAuthenticatedRequest("GET", "/billings"+query, nil, *tokenAdmin)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)

	// Event on query

	query = "?event="+url.QueryEscape(strconv.Itoa(Event1.ID))

	config.Authentication = true
	res, err = executeAuthenticatedRequest("GET", "/billings"+query, nil, *tokenAdmin)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)

	// Company on query

	query = "?company="+url.QueryEscape(company.ID.Hex())
	config.Authentication = true
	res, err = executeAuthenticatedRequest("GET", "/billings"+query, nil, *tokenAdmin)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)
}

func TestGetBillingsBadQuey(t *testing.T){
	defer mongodb.Billings.Collection.Drop(mongodb.Billings.Context)

	_, err := mongodb.Billings.CreateBilling(Billing1Data)
	assert.NilError(t, err)

	res, err := executeRequest("GET", "/billings?event=wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	res, err = executeRequest("GET", "/billings?valueLessThan=wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	res, err = executeRequest("GET", "/billings?valueGreaterThan=wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	res, err = executeRequest("GET", "/billings?after=wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	res, err = executeRequest("GET", "/billings?before=wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

}

func TestGetBilling(t *testing.T){
	defer mongodb.Billings.Collection.Drop(mongodb.Billings.Context)

	Billing1, err := mongodb.Billings.CreateBilling(Billing1Data)
	assert.NilError(t, err)

	Billing2, err = mongodb.Billings.CreateBilling(Billing2Data)
	assert.NilError(t, err)

	var billing models.Billing

	res, err := executeRequest("GET", "/billings/"+Billing1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billing)

	assert.Equal(t, billing.ID, Billing1.ID)

}

func TestCreateBilling(t *testing.T){
	defer mongodb.CompanyReps.Collection.Drop(mongodb.CompanyReps.Context)

	b, errMarshal := json.Marshal(Billing1Data)
	assert.NilError(t, errMarshal)

	var billing models.Billing

	res, err := executeRequest("POST" ,"/billings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billing)

	Billing1, err = mongodb.Billings.GetBilling(billing.ID)
	assert.NilError(t, err)

	assert.Equal(t, Billing1.Notes, billing.Notes)

}

func TestUpdateBilling(t *testing.T){
	defer mongodb.Billings.Collection.Drop(mongodb.Billings.Context)

	Billing1, err := mongodb.Billings.CreateBilling(Billing1Data)
	assert.NilError(t, err)

	b, errMarshal := json.Marshal(Billing2Data)
	assert.NilError(t, errMarshal)

	var billing models.Billing

	res, err := executeRequest("PUT" ,"/billings/" + Billing1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billing)

	assert.Equal(t, Billing2Notes, billing.Notes)
	assert.Equal(t, billing.ID, Billing1.ID)

}

func TestDeleteBilling(t *testing.T){
	defer mongodb.Billings.Collection.Drop(mongodb.Billings.Context)

	Billing1, err := mongodb.Billings.CreateBilling(Billing1Data)

	Billing2, err = mongodb.Billings.CreateBilling(Billing2Data)
	assert.NilError(t, err)

	var billing models.Billing

	res, err := executeRequest("DELETE", "/billings/"+Billing1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billing)

	assert.Equal(t, billing.ID, Billing1.ID)

	billings, err := mongodb.Billings.GetBillings(mongodb.GetBillingsOptions{})
	assert.NilError(t, err)
	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing2.ID)
}