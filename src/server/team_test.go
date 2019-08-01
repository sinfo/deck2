package server

import (
	"testing"
	//"fmt"

	"gotest.tools/assert"
	//is"gotest.tools/assert/cmp"

	"net/http"
	"net/http/httptest"
)


func TestGetTeamsHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/teams", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(GetTeamsHandler)

	handler.ServeHTTP(rr, req)

	assert.Equal(t, rr.Code, http.StatusOK)

	//fmt.Println(rr.Body.String())

	assert.Equal(t, rr.Body.String(), `[]`)
}


