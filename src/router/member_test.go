package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"testing"

	"go.mongodb.org/mongo-driver/bson"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"

	"gotest.tools/assert"
)

var (
	Member1Data = mongodb.CreateMemberData{
		Name:    "Member1",
		Istid:   "ist123456",
		SINFOID: "john.doe",
	}
	Member2Data = mongodb.CreateMemberData{
		Name:    "Member2",
		Istid:   "ist654321",
		SINFOID: "mary.jane",
	}
	Member1 *models.Member
	Member2 *models.Member
)

func containsMember(members []models.Member, member *models.Member) bool {
	for _, s := range members {
		if s.ID == member.ID && s.Name == member.Name {
			return true
		}
	}

	return false
}

func containsMemberPublic(members []models.MemberPublic, member *models.Member) bool {
	for _, s := range members {
		if s.Name == member.Name {
			return true
		}
	}

	return false
}

func TestGetMembers(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	Member2, err := mongodb.Members.CreateMember(Member2Data)
	if err != nil {
		log.Fatal(err)
	}

	var members []models.Member

	res, err := executeRequest("GET", "/members", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 2)
	assert.Equal(t, containsMember(members, Member1), true)
	assert.Equal(t, containsMember(members, Member2), true)

}

func TestGetMembersName(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	Member2, err := mongodb.Members.CreateMember(Member2Data)
	if err != nil {
		log.Fatal(err)
	}

	var members []models.Member
	var query = "?name=" + url.QueryEscape("member")

	res, err := executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 2)
	assert.Equal(t, containsMember(members, Member1), true)
	assert.Equal(t, containsMember(members, Member2), true)

	query = "?name=" + url.QueryEscape("1")

	res, err = executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 1)
	assert.Equal(t, containsMember(members, Member1), true)
	assert.Equal(t, containsMember(members, Member2), false)

	query = "?name=" + url.QueryEscape("a")

	res, err = executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 0)
	assert.Equal(t, containsMember(members, Member1), false)
	assert.Equal(t, containsMember(members, Member2), false)

}

func TestGetMembersEvent(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	_, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": 1, "name": "SINFO1"})
	assert.NilError(t, err)

	event1, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: "SINFO2"})
	assert.NilError(t, err)

	team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	Member1, err = mongodb.Members.CreateMember(Member1Data)
	assert.NilError(t, err)

	var role models.TeamRole = "MEMBER"

	team1, err = mongodb.Teams.AddTeamMember(team1.ID, mongodb.UpdateTeamMemberData{
		Member: &Member1.ID,
		Role:   &role,
	})
	assert.NilError(t, err)
	assert.Equal(t, len(team1.Members), 1)
	assert.Equal(t, team1.Members[0].Member, Member1.ID)

	var members []models.Member
	var query = "?event=" + url.QueryEscape(strconv.Itoa(event1.ID))

	res, err := executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 1)
	assert.Equal(t, members[0].ID, Member1.ID)

	// Test Duplicate member

	team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	team2, err = mongodb.Teams.AddTeamMember(team2.ID, mongodb.UpdateTeamMemberData{
		Member: &Member1.ID,
		Role:   &role,
	})
	assert.NilError(t, err)
	assert.Equal(t, len(team2.Members), 1)
	assert.Equal(t, team2.Members[0].Member, Member1.ID)

	res, err = executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 1)
	assert.Equal(t, members[0].ID, Member1.ID)
}

func TestGetMember(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/members/"+Member1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member models.Member

	json.NewDecoder(res.Body).Decode(&member)

	assert.Equal(t, Member1.Name, member.Name)
	assert.Equal(t, Member1.ID, member.ID)
}

func TestGetMemberBadID(t *testing.T) {
	res, err := executeRequest("GET", "/members/wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestCreateMember(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	b, errMarshal := json.Marshal(Member1Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member1, member2 models.Member

	json.NewDecoder(res.Body).Decode(&member1)

	assert.Equal(t, member1.Name, Member1Data.Name)

	res, err = executeRequest("GET", "/members/"+member1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&member2)

	assert.Equal(t, member2.Name, member1.Name)
	assert.Equal(t, member2.ID, member1.ID)
}

func TestCreateMemberBadPayload(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	cmdName := mongodb.CreateMemberData{
		Name:  "",
		Istid: "ist111111",
	}

	b, errMarshal := json.Marshal(cmdName)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdImage := mongodb.CreateMemberData{
		Name:  "Name",
		Istid: "ist111111",
	}

	b, errMarshal = json.Marshal(cmdImage)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstid0 := mongodb.CreateMemberData{
		Name:  "Name",
		Istid: "",
	}

	b, errMarshal = json.Marshal(cmdIstid0)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstidIst := mongodb.CreateMemberData{
		Name:  "Name",
		Istid: "123456",
	}

	b, errMarshal = json.Marshal(cmdIstidIst)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateMember(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	b, errMarshal := json.Marshal(Member2Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member models.Member

	json.NewDecoder(res.Body).Decode(&member)

	assert.Equal(t, Member2Data.Name, member.Name)
	assert.Equal(t, Member1.ID, member.ID)
}

func TestUpdateMemberBadPayload(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	cmdName := mongodb.CreateMemberData{
		Name:  "",
		Istid: "ist111111",
	}

	b, errMarshal := json.Marshal(cmdName)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstid0 := mongodb.CreateMemberData{
		Name:  "Name",
		Istid: "",
	}

	b, errMarshal = json.Marshal(cmdIstid0)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstidIst := mongodb.CreateMemberData{
		Name:  "Name",
		Istid: "123456",
	}

	b, errMarshal = json.Marshal(cmdIstidIst)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestCreateMemberContact(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Contacts.Collection.Drop(mongodb.Contacts.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	phone := models.ContactPhone{
		Phone: "123456789",
		Valid: true,
	}
	socials := models.ContactSocials{
		Facebook: "facebook",
		Skype:    "skype",
		Github:   "github",
		Twitter:  "twitter",
		LinkedIn: "linkedin",
	}
	mail := models.ContactMail{
		Mail:     "email@email.com",
		Valid:    true,
		Personal: true,
	}

	phonelist := make([]models.ContactPhone, 0)
	phonelist = append(phonelist, phone)

	maillist := make([]models.ContactMail, 0)
	maillist = append(maillist, mail)

	data := mongodb.CreateContactData{
		Phones:  phonelist,
		Socials: socials,
		Mails:   maillist,
	}

	b, errMarshal := json.Marshal(data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/members/"+Member1.ID.Hex()+"/contact", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member models.Member

	json.NewDecoder(res.Body).Decode(&member)

	contact, err := mongodb.Contacts.GetContact(member.Contact)
	assert.NilError(t, err)

	assert.Equal(t, contact.ID, member.Contact)
	assert.Equal(t, contact.Phones[0].Phone, phone.Phone)
	assert.Equal(t, contact.Mails[0].Mail, mail.Mail)
	assert.Equal(t, contact.Socials.Facebook, socials.Facebook)
	assert.Equal(t, contact.Socials.Skype, socials.Skype)
	assert.Equal(t, contact.Socials.Github, socials.Github)
	assert.Equal(t, contact.Socials.Twitter, socials.Twitter)
	assert.Equal(t, contact.Socials.LinkedIn, socials.LinkedIn)

}

func TestUpdateContactBadID(t *testing.T) {
	defer mongodb.Contacts.Collection.Drop(mongodb.Contacts.Context)

	data := mongodb.CreateContactData{
		Phones:  append(make([]models.ContactPhone, 0), models.ContactPhone{Phone: "a", Valid: true}),
		Socials: models.ContactSocials{},
		Mails:   append(make([]models.ContactMail, 0), models.ContactMail{Mail: "a", Valid: true, Personal: true}),
	}

	b, errMarshal := json.Marshal(data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/members/wrong/contact", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestGetMembersPublic(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	Member2, err := mongodb.Members.CreateMember(Member2Data)
	if err != nil {
		log.Fatal(err)
	}

	var members []models.MemberPublic

	res, err := executeRequest("GET", "/public/members", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 2)
	assert.Equal(t, containsMemberPublic(members, Member1), true)
	assert.Equal(t, containsMemberPublic(members, Member2), true)

}

func TestGetMembersPublicName(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	Member2, err := mongodb.Members.CreateMember(Member2Data)
	if err != nil {
		log.Fatal(err)
	}

	var members []models.MemberPublic
	var query = "?name=" + url.QueryEscape("member")

	res, err := executeRequest("GET", "/public/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 2)
	assert.Equal(t, containsMemberPublic(members, Member1), true)
	assert.Equal(t, containsMemberPublic(members, Member2), true)

	query = "?name=" + url.QueryEscape("1")

	res, err = executeRequest("GET", "/public/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 1)
	assert.Equal(t, containsMemberPublic(members, Member1), true)
	assert.Equal(t, containsMemberPublic(members, Member2), false)

	query = "?name=" + url.QueryEscape("a")

	res, err = executeRequest("GET", "/public/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 0)
	assert.Equal(t, containsMemberPublic(members, Member1), false)
	assert.Equal(t, containsMemberPublic(members, Member2), false)

}

func TestGetMembersPublicEvent(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	_, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": 1, "name": "SINFO1"})
	assert.NilError(t, err)

	event1, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: "SINFO2"})
	assert.NilError(t, err)

	team1, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	Member1, err = mongodb.Members.CreateMember(Member1Data)
	assert.NilError(t, err)

	var role models.TeamRole = "MEMBER"

	team1, err = mongodb.Teams.AddTeamMember(team1.ID, mongodb.UpdateTeamMemberData{
		Member: &Member1.ID,
		Role:   &role,
	})
	assert.NilError(t, err)
	assert.Equal(t, len(team1.Members), 1)
	assert.Equal(t, team1.Members[0].Member, Member1.ID)

	var members []models.MemberPublic
	var query = "?event=" + url.QueryEscape(strconv.Itoa(event1.ID))

	res, err := executeRequest("GET", "/public/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 1)
	assert.Equal(t, members[0].Name, Member1.Name)

	// Test Duplicate member

	team2, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	team2, err = mongodb.Teams.AddTeamMember(team2.ID, mongodb.UpdateTeamMemberData{
		Member: &Member1.ID,
		Role:   &role,
	})
	assert.NilError(t, err)
	assert.Equal(t, len(team2.Members), 1)
	assert.Equal(t, team2.Members[0].Member, Member1.ID)

	res, err = executeRequest("GET", "/public/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 1)
	assert.Equal(t, members[0].Name, Member1.Name)
}
