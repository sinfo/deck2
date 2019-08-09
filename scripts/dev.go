package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
)

var (
	timeBefore = time.Now().Add(-time.Hour * 24 * 3)
	timeNow    = time.Now()
	timeAfter  = time.Now().Add(time.Hour * 24 * 3)
	event      = models.Event{
		ID:    2,
		Name:  "dummy event",
		Begin: &timeBefore,
		End:   &timeAfter,
	}
	team = models.Team{
		Name: "dummy team",
	}
)

func onError(err error) {
	mongodb.Events.Collection.Drop(mongodb.Events.Context)
	mongodb.Members.Collection.Drop(mongodb.Members.Context)
	mongodb.Teams.Collection.Drop(mongodb.Teams.Context)

	log.Fatal(err)
}

func main() {
	mongodb.InitializeDatabase()

	var text string
	var memberName string
	var memberSINFOID string

	reader := bufio.NewReader(os.Stdin)

	fmt.Print("****** Development script ******\n")
	fmt.Print("****** On error, drops events, teams and members collections ******\n\n")

	fmt.Print("Member name: ")
	text, _ = reader.ReadString('\n')
	memberName = text[:len(text)-1]

	fmt.Print("Member sinfo ID (example: john.doe@sinfo.org has john.doe as sinfo ID): ")
	text, _ = reader.ReadString('\n')
	memberSINFOID = text[:len(text)-1]

	var level = 0
	for level < 1 || level > 4 {
		fmt.Println("Credentials level:")
		fmt.Println("1. Member")
		fmt.Println("2. Team Leader")
		fmt.Println("3. Coordinator")
		fmt.Println("4. Admin")
		fmt.Print("Level: ")
		fmt.Scanf("%d", &level)
	}

	var role models.TeamRole
	switch level {
	case 1:
		role = models.RoleMember
	case 2:
		role = models.RoleTeamLeader
	case 3:
		role = models.RoleCoordinator
	case 4:
		role = models.RoleAdmin
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id":   1,
		"name":  event.Name,
		"begin": *event.Begin,
		"end":   *event.End,
	}); err != nil {
		onError(err)
	}

	ced := mongodb.CreateEventData{Name: event.Name}
	createdEvent, err := mongodb.Events.CreateEvent(ced)
	if err != nil {
		onError(err)
	}

	ued := mongodb.UpdateEventData{
		Name:  event.Name,
		Begin: *event.Begin,
		End:   *event.End,
	}
	if _, err := mongodb.Events.UpdateEvent(createdEvent.ID, ued); err != nil {
		onError(err)
	}

	cmd := mongodb.CreateMemberData{
		Name:    memberName,
		Istid:   "ist12345",
		SinfoID: memberSINFOID,
	}

	member, err := mongodb.Members.CreateMember(cmd)
	if err != nil {
		onError(err)
	}

	ctd := mongodb.CreateTeamData{Name: team.Name}
	newTeam, err := mongodb.Teams.CreateTeam(ctd)
	if err != nil {
		onError(err)
	}

	team = *newTeam

	utmd := mongodb.UpdateTeamMemberData{
		Member: &member.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(team.ID, utmd)
	if err != nil {
		onError(err)
	}
}
