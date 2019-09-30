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
	Events			*EventsType
	Companies  		*CompaniesType
	Speakers   		*SpeakersType
	Teams      		*TeamsType
	Members    		*MembersType
	Items      		*ItemsType
	Packages   		*PackagesType
	Meetings   		*MeetingsType
	Contacts   		*ContactsType
	Threads    		*ThreadsType
	Posts      		*PostsType
	FlightInfo 		*FlightInfoType
	Sessions   		*SessionsType
	Billings   		*BillingsType
	CompanyReps		*CompanyRepsType
	Notifications	*NotificationsType
	Tokens			*TokensType
)

var (
	indexUnique = true
)

const (
	cacheCleanupPeriod = 1 * time.Hour
)

// In case you decide to run many instances of this program at the same time (for example
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

	db = client.Database(config.DatabaseName)

	Events = &EventsType{
		Collection: db.Collection("events"),
		Context:    ctx,
	}

	Companies = &CompaniesType{
		Collection: db.Collection("companies"),
		Context:    ctx,
	}

	Speakers = &SpeakersType{
		Collection: db.Collection("speakers"),
		Context:    ctx,
	}

	Teams = &TeamsType{
		Collection: db.Collection("teams"),
		Context:    ctx,
	}

	Members = &MembersType{
		Collection: db.Collection("members"),
		Context:    ctx,
	}

	Items = &ItemsType{
		Collection: db.Collection("items"),
		Context:    ctx,
	}

	Packages = &PackagesType{
		Collection: db.Collection("packages"),
		Context:    ctx,
	}

	Meetings = &MeetingsType{
		Collection: db.Collection("meetings"),
		Context:    ctx,
	}

	Contacts = &ContactsType{
		Collection: db.Collection("contacts"),
		Context:    ctx,
	}

	Threads = &ThreadsType{
		Collection: db.Collection("threads"),
		Context:    ctx,
	}

	Posts = &PostsType{
		Collection: db.Collection("posts"),
		Context:    ctx,
	}

	FlightInfo = &FlightInfoType{
		Collection: db.Collection("flightInfo"),
		Context:    ctx,
	}

	Sessions = &SessionsType{
		Collection: db.Collection("sessions"),
		Context:    ctx,
	}

	Billings = &BillingsType{
		Collection: db.Collection("billings"),
		Context:	ctx,
	}

	CompanyReps = &CompanyRepsType{
		Collection:	db.Collection("companyReps"),
		Context:	ctx,
	}
	
	Notifications = &NotificationsType{
		Collection: db.Collection("notifications"),
		Context:    ctx,
	}

	Tokens = &TokensType{
		Collection:	db.Collection("tokens"),
		Context:	ctx,
	}

	log.Println("Connected to the database successfully")

	go CleanupCache()
}
