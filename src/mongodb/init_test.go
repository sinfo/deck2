package mongodb

import (
	"log"
	"os"
	"testing"

	"github.com/globalsign/mgo/bson"
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