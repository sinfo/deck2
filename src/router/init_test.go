package router

import (
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/sinfo/deck2/src/mongodb"
)

func executeRequest(method string, path string, payload io.Reader) (*httptest.ResponseRecorder, error) {
	req, errReq := http.NewRequest(method, path, payload)

	if errReq != nil {
		return nil, errReq
	}

	rr := httptest.NewRecorder()
	Router.ServeHTTP(rr, req)

	return rr, nil
}

func TestMain(m *testing.M) {

	// Database setup
	mongodb.InitializeDatabase()

	// Router setup
	InitializeRouter()

	retCode := m.Run()
	os.Exit(retCode)
}
