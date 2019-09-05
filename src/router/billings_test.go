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
	//"log"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"gotest.tools/assert"
	//"go.mongodb.org/mongo-driver/bson"
)

var (
	Billing1	*models.Billing
	Billing2	*models.Billing
	FALSE = false
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
	defer mongodb.Billings.Collection.Drop(mongodb.Billings.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	company, err := mongodb.Companies.CreateCompany(mongodb.CreateCompanyData{
		Name: &Company.Name,
		Description: &Company.Description,
		Site: &Company.Site,
		
	})
	assert.NilError(t, err)

	Billing1Data.Company = &company.ID

	Billing1, err := mongodb.Billings.CreateBilling(Billing1Data)
	assert.NilError(t, err)

	Billing1Data.Company = nil

	Billing2, err = mongodb.Billings.CreateBilling(Billing2Data)
	assert.NilError(t, err)

	var billings []*models.Billing

	// No Query

	res, err := executeRequest("GET", "/billings", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 2)

	// After on query

	var query = "?after="+ url.QueryEscape(TimeAfter.Format(time.RFC3339))

	res, err = executeRequest("GET", "/billings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing2.ID)

	// Before on query

	query = "?before="+url.QueryEscape(TimeAfter.Format(time.RFC3339))

	res, err = executeRequest("GET", "/billings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)

	// ValueGreaterThan on query

	query = "?valueGreaterThan="+url.QueryEscape(strconv.Itoa(600))

	res, err = executeRequest("GET", "/billings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing2.ID)

	// ValueLessThan on query

	query = "?valueLessThan="+url.QueryEscape(strconv.Itoa(600))

	res, err = executeRequest("GET", "/billings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)

	// Event on query

	query = "?event="+url.QueryEscape(strconv.Itoa(Event1.ID))

	res, err = executeRequest("GET", "/billings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&billings)

	assert.Equal(t, len(billings), 1)
	assert.Equal(t, billings[0].ID, Billing1.ID)

	// Company on query

	query = "?company="+url.QueryEscape(company.ID.Hex())

	res, err = executeRequest("GET", "/billings"+query, nil)
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