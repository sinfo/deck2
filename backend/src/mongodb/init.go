package mongodb

import (
	"context"
	"log"
	"time"

	"github.com/sinfo/deck2/src/config"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var ctx context.Context
var db *mongo.Database

var (
	//Events is an instance of a mongodb collection
	Events *EventsType
	//Companies is an instance of a mongodb collection
	Companies *CompaniesType
	//Speakers is an instance of a mongodb collection
	Speakers *SpeakersType
	//Teams is an instance of a mongodb collection
	Teams *TeamsType
	//Members is an instance of a mongodb collection
	Members *MembersType
	//Items is an instance of a mongodb collection
	Items *ItemsType
	//Packages is an instance of a mongodb collection
	Packages *PackagesType
	//Meetings is an instance of a mongodb collection
	Meetings *MeetingsType
	//Contacts is an instance of a mongodb collection
	Contacts *ContactsType
	//Threads is an instance of a mongodb collection
	Threads *ThreadsType
	//Posts is an instance of a mongodb collection
	Posts *PostsType
	//FlightInfo is an instance of a mongodb collection
	FlightInfo *FlightInfoType
	//Sessions is an instance of a mongodb collection
	Sessions *SessionsType
	//Billings is an instance of a mongodb collection
	Billings *BillingsType
	//CompanyReps is an instance of a mongodb collection
	CompanyReps *CompanyRepsType
	//Notifications is an instance of a mongodb collection
	Notifications *NotificationsType
)

var (
	indexUnique = true
)

const (
	cacheCleanupPeriod = 1 * time.Hour
)

// CleanupCache : In case you decide to run many instances of this program at the same time (for example
// using a load balancer), the cached versions between these instances will not coincide.
// A workaround is to just clean up the cached content every X time.
func CleanupCache() {
	ticker := time.NewTicker(cacheCleanupPeriod)
	defer ticker.Stop()

	for range ticker.C {
		ResetCurrentPublicEvent()
		ResetCurrentPublicCompanies()
		ResetCurrentPublicMembers()
		ResetCurrentPublicSpeakers()
		ResetCurrentPublicSessions()

		log.Println("Cleaned up cache")
	}

}

// InitializeDatabase initializes the database connection
func InitializeDatabase() {

	client, err := mongo.NewClient(options.Client().ApplyURI(config.DatabaseURI))
	if err != nil {
		log.Fatal(err)
		return
	}

	ctx = context.Background()

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

	db = client.Database(config.DatabaseName)

	Events = &EventsType{
		Collection: db.Collection("events"),
	}

	Companies = &CompaniesType{
		Collection: db.Collection("companies"),
	}

	Speakers = &SpeakersType{
		Collection: db.Collection("speakers"),
	}

	Teams = &TeamsType{
		Collection: db.Collection("teams"),
	}

	Members = &MembersType{
		Collection: db.Collection("members"),
	}

	Items = &ItemsType{
		Collection: db.Collection("items"),
	}

	Packages = &PackagesType{
		Collection: db.Collection("packages"),
	}

	Meetings = &MeetingsType{
		Collection: db.Collection("meetings"),
	}

	Contacts = &ContactsType{
		Collection: db.Collection("contacts"),
	}

	Threads = &ThreadsType{
		Collection: db.Collection("threads"),
	}

	Posts = &PostsType{
		Collection: db.Collection("posts"),
	}

	FlightInfo = &FlightInfoType{
		Collection: db.Collection("flightInfo"),
	}

	Sessions = &SessionsType{
		Collection: db.Collection("sessions"),
	}

	Billings = &BillingsType{
		Collection: db.Collection("billings"),
	}

	CompanyReps = &CompanyRepsType{
		Collection: db.Collection("companyReps"),
	}

	Notifications = &NotificationsType{
		Collection: db.Collection("notifications"),
	}

	log.Println("Connected to the database successfully")

	go CleanupCache()
}
