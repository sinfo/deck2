package mongodb

import (
	"context"
	"log"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var ctx context.Context
var db *mongo.Database

var (
	Events		*EventsType
	Companies	*CompaniesType
	Teams     	*TeamsType
	Members	  	*MembersType		
	Items 		*ItemsType
)

// InitializeDatabase initializes the database connection
func InitializeDatabase() {

	client, err := mongo.NewClient(options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		log.Fatal(err)
		return
	}

	ctx := context.Background()

	err = client.Connect(ctx)
	if err != nil {
		log.Fatal(err)
		return
	}

	// Check the connection
	err = client.Ping(ctx, nil)

	if err != nil {
		log.Fatal(err)
	}

	db = client.Database("deck2_testing")

	Events = &EventsType{
		Collection: db.Collection("events"),
		Context:    ctx,
	}

	Companies = &CompaniesType{
		Collection: db.Collection("companies"),
		Context:    ctx,
	}

	Teams = &TeamsType{
		Collection: db.Collection("teams"),
		Context:    ctx,
	}

	Members = &MembersType{
		Collection: db.Collection("members"),
		Context:	ctx,
	}
	
	Items = &ItemsType{
		Collection: db.Collection("items"),
		Context:    ctx,
	}

	log.Println("Connected to the database successfully")
}
