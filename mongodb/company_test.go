package mongodb

import (
	"fmt"
	"log"
	"os"
	"testing"

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

	assert.NilError(err)

	fmt.Println("created company: ", newCompany)
}

func TestAddParticipation(t *testing.T) {

	var name = "MyCompany Inc"
	var description = "This is a really cool company"
	var site = "mycompany.net"

	company, _ := CreateCompany(name, description, site)

	companies.Drop(ctx)

	updatedCompany, err := AddParticipation(company.ID, "some_member", true)

	if err != nil {
		log.Fatal("Caugh an error!", err)
	}

	fmt.Println("updated company: ", updatedCompany)
}
