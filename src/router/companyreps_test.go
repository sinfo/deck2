package router

import (
	"bytes"
	"encoding/json"
	"net/http"
	"testing"
	"net/url"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"gotest.tools/assert"
)

var (
	Name1 = "NAME1"
	Name2 = "NAME2"
)

func TestGetCompanyReps(t *testing.T){
	defer mongodb.CompanyReps.Collection.Drop(mongodb.CompanyReps.Context)

	rep1, err := mongodb.CompanyReps.CreateCompanyRep(mongodb.CreateCompanyRepData{Name: &Name1})
	assert.NilError(t, err)

	_, err = mongodb.CompanyReps.CreateCompanyRep(mongodb.CreateCompanyRepData{Name: &Name2})
	assert.NilError(t, err)

	var query = "?name="+url.QueryEscape(Name1)
	res, err := executeRequest("GET", "/companyReps"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var reps []*models.CompanyRep

	json.NewDecoder(res.Body).Decode(&reps)

	assert.Equal(t, len(reps), 1)
	assert.Equal(t,rep1.ID, reps[0].ID)

	res, err = executeRequest("GET", "/companyReps", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&reps)

	assert.Equal(t, len(reps), 2)
}

func TestGetCompanyRep(t *testing.T){
	defer mongodb.CompanyReps.Collection.Drop(mongodb.CompanyReps.Context)

	rep1, err := mongodb.CompanyReps.CreateCompanyRep(mongodb.CreateCompanyRepData{Name: &Name1})
	assert.NilError(t, err)

	_, err = mongodb.CompanyReps.CreateCompanyRep(mongodb.CreateCompanyRepData{Name: &Name2})
	assert.NilError(t, err)

	res, err := executeRequest("GET", "/companyReps/"+rep1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var rep models.CompanyRep

	json.NewDecoder(res.Body).Decode(&rep)

	assert.Equal(t,rep1.ID, rep.ID)

	res, err = executeRequest("GET", "/companyReps/wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdateCompanyRep(t *testing.T){
	defer mongodb.CompanyReps.Collection.Drop(mongodb.CompanyReps.Context)

	rep1, err := mongodb.CompanyReps.CreateCompanyRep(mongodb.CreateCompanyRepData{Name: &Name1})
	assert.NilError(t, err)

	ucrp := &mongodb.CreateCompanyRepData{
		Name: &Name2,
	}

	b, errMarshal := json.Marshal(ucrp)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/companyReps/"+rep1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var rep models.CompanyRep

	json.NewDecoder(res.Body).Decode(&rep)

	assert.Equal(t, rep.Name, Name2)
	assert.Equal(t, rep.ID, rep1.ID)
}