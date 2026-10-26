package router

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"gotest.tools/assert"
)

var (
	Company = models.Company{Name: "some-name", Description: "some-description", Site: "some-site"}
)

func TestCreateCompany(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newCompany models.Company

	createCompanyData := &mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	b, errMarshal := json.Marshal(createCompanyData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/companies", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newCompany)

	assert.Equal(t, newCompany.Name, Company.Name)
	assert.Equal(t, newCompany.Description, Company.Description)
	assert.Equal(t, newCompany.Site, Company.Site)
}

func TestCreateCompanyInvalidPayload(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	type InvalidPayload struct {
		Name string `json:"name"`
	}

	createCompanyData := &InvalidPayload{
		Name: Company.Name,
	}

	b, errMarshal := json.Marshal(createCompanyData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/companies", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetCompanies(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	var companies []models.Company

	res, err := executeRequest("GET", "/companies", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&companies)

	assert.Equal(t, len(companies) == 1, true)
	assert.Equal(t, companies[0].ID, newCompany.ID)
}

func TestGetCompany(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	var company models.Company

	res, err := executeRequest("GET", "/companies/"+newCompany.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&company)

	assert.Equal(t, company.ID, newCompany.ID)
}

func TestGetCompanyPublic(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	var company models.CompanyPublic

	res, err := executeRequest("GET", "/public/companies/"+newCompany.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&company)

	assert.Equal(t, company.ID, newCompany.ID)
	assert.Equal(t, company.Image, newCompany.Images.Public)
}

func TestGetCompanyNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/companies/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddCompanyParticipation(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := &mongodb.AddParticipationData{
		Partner: false,
	}

	b, errMarshal := json.Marshal(apd)
	assert.NilError(t, errMarshal)

	var updatedCompany models.Company

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/participation", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)
	assert.Equal(t, updatedCompany.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedCompany.Participations[0].Member, newMember.ID)

}

func TestAddCompanyParticipationAlreadyIsParticipating(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	_, err = mongodb.Companies.AddParticipation(newCompany.ID, newMember.ID, mongodb.AddParticipationData{
		Partner: true,
	})
	assert.NilError(t, err)

	apd := &mongodb.AddParticipationData{
		Partner: false,
	}

	b, errMarshal := json.Marshal(apd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/participation", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddCompanyThread(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	var text = "some text"
	var meeting *mongodb.CreateMeetingData
	var kind = models.ThreadKindTo

	atd := &addThreadData{
		Text:    &text,
		Meeting: meeting,
		Kind:    &kind,
	}

	b, errMarshal := json.Marshal(atd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/thread", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)
	assert.Equal(t, updatedCompany.Participations[0].Event, Event1.ID)
	assert.Equal(t, len(updatedCompany.Participations[0].Communications), 1)

	threadID := updatedCompany.Participations[0].Communications[0]

	thread, err := mongodb.Threads.GetThread(threadID)
	assert.NilError(t, err)

	thread.Kind = kind
	thread.Status = models.ThreadStatusPending

	post, err := mongodb.Posts.GetPost(thread.Entry)
	assert.NilError(t, err)

	assert.Equal(t, post.Member, credentials.ID)
	assert.Equal(t, post.Text, text)
}

func TestAddCompanyThreadInvalidPayload(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	_, err = mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	type InvalidPayload struct {
		Text string
	}

	invalidPayload := &InvalidPayload{Text: "some text"}

	b, errMarshal := json.Marshal(invalidPayload)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/thread", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddCompanyThreadCompanyNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("POST", "/companies/"+primitive.NewObjectID().Hex()+"/thread", bytes.NewBuffer([]byte{}))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddCompanyThreadNoParticipation(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	var text = "some text"
	var meeting *mongodb.CreateMeetingData
	var kind = models.ThreadKindTo

	atd := &addThreadData{
		Text:    &text,
		Meeting: meeting,
		Kind:    &kind,
	}

	b, errMarshal := json.Marshal(atd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/thread", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusExpectationFailed)
}

func TestAddCompanyThreadMeeting(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	var text = "some text"
	var place = "some place"
	var participants = models.MeetingParticipants{
		Members:     []primitive.ObjectID{},
		CompanyReps: []primitive.ObjectID{},
	}
	var meetingData = mongodb.CreateMeetingData{
		Begin:        &TimeBefore,
		End:          &TimeNow,
		Place:        &place,
		Participants: &participants,
	}
	var kind = models.ThreadKindMeeting

	atd := &addThreadData{
		Text:    &text,
		Meeting: &meetingData,
		Kind:    &kind,
	}

	b, errMarshal := json.Marshal(atd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/thread", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)
	assert.Equal(t, updatedCompany.Participations[0].Event, Event1.ID)
	assert.Equal(t, len(updatedCompany.Participations[0].Communications), 1)

	threadID := updatedCompany.Participations[0].Communications[0]

	thread, err := mongodb.Threads.GetThread(threadID)
	assert.NilError(t, err)

	thread.Kind = kind
	thread.Status = models.ThreadStatusPending

	meeting, err := mongodb.Meetings.GetMeeting(*thread.Meeting)
	assert.NilError(t, err)

	assert.Equal(t, meeting.Place, place)
	assert.Equal(t, len(meeting.Participants.Members), 0)
	assert.Equal(t, len(meeting.Participants.CompanyReps), 0)
	assert.Equal(t, meeting.Begin.Sub(TimeBefore).Seconds() < 10e-3, true) // millisecond precision
	assert.Equal(t, meeting.End.Sub(TimeNow).Seconds() < 10e-3, true)      // millisecond precision

	post, err := mongodb.Posts.GetPost(thread.Entry)
	assert.NilError(t, err)

	assert.Equal(t, post.Member, credentials.ID)
	assert.Equal(t, post.Text, text)
}

func TestAddCompanyThreadMeetingDataMissing(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	_, err = mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	var text = "some text"
	var meetingData = mongodb.CreateMeetingData{}
	var kind = models.ThreadKindMeeting

	atd := &addThreadData{
		Text:    &text,
		Meeting: &meetingData,
		Kind:    &kind,
	}

	b, errMarshal := json.Marshal(atd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/thread", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddCompanyPackage(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleCoordinator

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	cid := mongodb.CreateItemData{Name: Item.Name, Type: Item.Type, Description: Item.Description, Price: Item.Price, VAT: Item.VAT}
	item, err := mongodb.Items.CreateItem(cid)
	assert.NilError(t, err)

	var name = "some name"
	var vat = 23
	var price = 1400

	var quantity = 1
	var public = true

	cpd := &mongodb.CreatePackageData{
		Name: &name,
		Items: &([]models.PackageItem{
			models.PackageItem{
				Item:     item.ID,
				Quantity: quantity,
				Public:   public,
			},
		}),
		Price: &price,
		VAT:   &vat,
	}

	b, errMarshal := json.Marshal(cpd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/participation/package", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)

	var packageID = updatedCompany.Participations[0].Package

	createdPackage, err := mongodb.Packages.GetPackage(*packageID)
	assert.NilError(t, err)

	assert.Equal(t, createdPackage.Name, name)
	assert.Equal(t, createdPackage.Price, price)
	assert.Equal(t, createdPackage.VAT, vat)
	assert.Equal(t, len(createdPackage.Items), 1)
	assert.Equal(t, createdPackage.Items[0].Item, item.ID)
	assert.Equal(t, createdPackage.Items[0].Public, public)
	assert.Equal(t, createdPackage.Items[0].Quantity, quantity)
}

func TestAddCompanyPackageItemNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleCoordinator

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	_, err = mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	var name = "some name"
	var vat = 23
	var price = 1400

	var quantity = 1
	var public = true

	cpd := &mongodb.CreatePackageData{
		Name: &name,
		Items: &([]models.PackageItem{
			models.PackageItem{
				Item:     primitive.NewObjectID(),
				Quantity: quantity,
				Public:   public,
			},
		}),
		Price: &price,
		VAT:   &vat,
	}

	b, errMarshal := json.Marshal(cpd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/participation/package", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	packages, err := mongodb.Packages.GetPackages(mongodb.GetPackagesOptions{})
	assert.NilError(t, err)
	assert.Equal(t, len(packages), 0)
}

func TestAddCompanyPackageNoParticipation(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleCoordinator

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	cid := mongodb.CreateItemData{Name: Item.Name, Type: Item.Type, Description: Item.Description, Price: Item.Price, VAT: Item.VAT}
	item, err := mongodb.Items.CreateItem(cid)
	assert.NilError(t, err)

	var name = "some name"
	var vat = 23
	var price = 1400

	var quantity = 1
	var public = true

	cpd := &mongodb.CreatePackageData{
		Name: &name,
		Items: &([]models.PackageItem{
			models.PackageItem{
				Item:     item.ID,
				Quantity: quantity,
				Public:   public,
			},
		}),
		Price: &price,
		VAT:   &vat,
	}

	b, errMarshal := json.Marshal(cpd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/companies/"+newCompany.ID.Hex()+"/participation/package", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusExpectationFailed)

	packages, err := mongodb.Packages.GetPackages(mongodb.GetPackagesOptions{})
	assert.NilError(t, err)
	assert.Equal(t, len(packages), 0)
}

func TestUpdateCompany(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	name := "some other name"
	description := "some other description"
	site := "some other site"

	ucd := &mongodb.UpdateCompanyData{
		Name:        &name,
		Description: &description,
		Site:        &site,
		BillingInfo: &models.CompanyBillingInfo{
			Name:    "some billing name",
			Address: "some billing address",
			TIN:     "some billing tin",
		},
	}

	b, errMarshal := json.Marshal(ucd)
	assert.NilError(t, errMarshal)

	var updatedCompany models.Company

	res, err := executeRequest("PUT", "/companies/"+newCompany.ID.Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, updatedCompany.Name, ucd.Name)
	assert.Equal(t, updatedCompany.Description, ucd.Description)
	assert.Equal(t, updatedCompany.Site, ucd.Site)
	assert.Equal(t, updatedCompany.BillingInfo.Name, ucd.BillingInfo.Name)
	assert.Equal(t, updatedCompany.BillingInfo.Address, ucd.BillingInfo.Address)
	assert.Equal(t, updatedCompany.BillingInfo.TIN, ucd.BillingInfo.TIN)
}

func TestUpdateCompanyInvalidPayload(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	description := "some other description"
	site := "some other site"

	ucd := &mongodb.UpdateCompanyData{
		Description: &description,
		Site:        &site,
		BillingInfo: &models.CompanyBillingInfo{
			Name:    "some billing name",
			Address: "some billing address",
			TIN:     "some billing tin",
		},
	}

	b, errMarshal := json.Marshal(ucd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/companies/"+newCompany.ID.Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateCompanyNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	name := "some other name"
	description := "some other description"
	site := "some other site"

	ucd := &mongodb.UpdateCompanyData{
		Name:        &name,
		Description: &description,
		Site:        &site,
		BillingInfo: &models.CompanyBillingInfo{
			Name:    "some billing name",
			Address: "some billing address",
			TIN:     "some billing tin",
		},
	}

	b, errMarshal := json.Marshal(ucd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/companies/"+primitive.NewObjectID().Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestDeleteCompany(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	var company models.Company

	res, err := executeRequest("DELETE", "/companies/"+newCompany.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&company)

	assert.Equal(t, company.ID, newCompany.ID)

	companies, err := mongodb.Companies.GetCompanies(mongodb.GetCompaniesOptions{})
	assert.NilError(t, err)

	assert.Equal(t, len(companies), 0)
}

func TestDeleteCompanyInvalidID(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("DELETE", "/companies/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestSetCompanyStatus(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	assert.Equal(t, updatedCompany.Participations[0].Status, models.Suggested)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("PUT", "/companies/"+newCompany.ID.Hex()+"/participation/status/"+string(models.Announced), nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)
	assert.Equal(t, updatedCompany.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedCompany.Participations[0].Status, models.Announced)
}

func TestSetCompanyStatusNoParticipation(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("PUT", "/companies/"+newCompany.ID.Hex()+"/participation/status/"+string(models.Announced), nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusExpectationFailed)
}

func TestSetCompanyStatusInvalidCompany(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("PUT", "/companies/"+primitive.NewObjectID().Hex()+"/participation/status/"+string(models.Announced), nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestSetCompanyStatusInvalidStatus(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	assert.Equal(t, updatedCompany.Participations[0].Status, models.Suggested)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("PUT", "/companies/"+newCompany.ID.Hex()+"/participation/status/someinvalidstatus", nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestListCompanyValidSteps(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	assert.Equal(t, updatedCompany.Participations[0].Status, models.Suggested)

	res, err := executeRequest("GET", "/companies/"+newCompany.ID.Hex()+"/participation/status/next", nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var validSteps validStepsResponse

	json.NewDecoder(res.Body).Decode(&validSteps)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(validSteps.Steps) > 0, true)
}

func TestStepCompanyStatus(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	assert.Equal(t, updatedCompany.Participations[0].Status, models.Suggested)

	validSteps, err := mongodb.Companies.GetCompanyParticipationStatusValidSteps(newCompany.ID)
	assert.NilError(t, err)
	assert.Equal(t, validSteps != nil, true)
	assert.Equal(t, len(*validSteps) > 0, true)

	var step = (*validSteps)[0].Step
	var status = (*validSteps)[0].Next

	res, err := executeRequest("POST", "/companies/"+newCompany.ID.Hex()+"/participation/status/"+strconv.Itoa(step), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)
	assert.Equal(t, updatedCompany.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedCompany.Participations[0].Status, status)
}

func TestUpdateCompanyParticipation(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	apd := mongodb.AddParticipationData{
		Partner: false,
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, credentials.ID, apd)
	assert.NilError(t, err)

	var newPartner = true
	var confirmed = time.Now()
	var notes = "some random notes about this specific company"

	ucpd := mongodb.UpdateCompanyParticipationData{
		Member:    &newMember.ID,
		Partner:   &newPartner,
		Confirmed: &confirmed,
		Notes:     &notes,
	}

	b, errMarshal := json.Marshal(ucpd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/companies/"+newCompany.ID.Hex()+"/participation", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, updatedCompany.ID, newCompany.ID)
	assert.Equal(t, len(updatedCompany.Participations), 1)
	assert.Equal(t, updatedCompany.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedCompany.Participations[0].Member, newMember.ID)
	assert.Equal(t, updatedCompany.Participations[0].Partner, newPartner)
	assert.Equal(t, updatedCompany.Participations[0].Notes, notes)
	assert.Equal(t, updatedCompany.Participations[0].Confirmed.Sub(confirmed).Seconds() < 10e-3, true) // millisecond precision
}

func TestAddEmployer(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.CompanyReps.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	var name1 = "NAME1"
	var name2 = "NAME2"
	var company models.Company

	ccrd1 := mongodb.CreateCompanyRepData{
		Name: &name1,
	}

	ccrd2 := mongodb.CreateCompanyRepData{
		Name:    &name2,
		Contact: &Contact1Data,
	}

	b, errMarshal := json.Marshal(ccrd1)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/companies/"+newCompany.ID.Hex()+"/employer", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&company)

	assert.Equal(t, company.ID, newCompany.ID)
	assert.Equal(t, len(company.Employers), 1)

	b, errMarshal = json.Marshal(ccrd2)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/companies/"+newCompany.ID.Hex()+"/employer", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&company)

	assert.Equal(t, company.ID, newCompany.ID)
	assert.Equal(t, len(company.Employers), 2)
}

func TestRemoveEmployer(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.CompanyReps.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	var name1 = "NAME1"
	var name2 = "NAME2"
	var company models.Company

	ccrd1 := mongodb.CreateCompanyRepData{
		Name: &name1,
	}

	ccrd2 := mongodb.CreateCompanyRepData{
		Name:    &name2,
		Contact: &Contact1Data,
	}

	newCompany, err = mongodb.Companies.AddEmployer(newCompany.ID, ccrd1)
	assert.NilError(t, err)

	newCompany, err = mongodb.Companies.AddEmployer(newCompany.ID, ccrd2)
	assert.NilError(t, err)

	res, err := executeRequest("DELETE", "/companies/"+newCompany.ID.Hex()+"/employer/"+newCompany.Employers[0].Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&company)

	assert.Equal(t, company.ID, newCompany.ID)
	assert.Equal(t, len(company.Employers), 1)
}

func createRelationshipTestCompany(t *testing.T, name string) *models.Company {
	company, err := mongodb.Companies.CreateCompany(mongodb.CreateCompanyData{Name: &name})
	assert.NilError(t, err)
	return company
}

func addRelationshipRequest(t *testing.T, companyID primitive.ObjectID, relType models.CompanyRelationshipType, targetID primitive.ObjectID) *httptest.ResponseRecorder {
	b, errMarshal := json.Marshal(mongodb.CompanyRelationshipData{Type: &relType, Company: &targetID})
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/companies/"+companyID.Hex()+"/relationships", bytes.NewBuffer(b))
	assert.NilError(t, err)
	return res
}

func TestAddCompanyRelationship(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	wpp := createRelationshipTestCompany(t, "WPP")
	vml := createRelationshipTestCompany(t, "VML")

	res := addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, wpp.ID)
	assert.Equal(t, res.Code, http.StatusOK)

	var updatedCompany models.Company
	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Equal(t, len(updatedCompany.Relationships), 1)
	assert.Equal(t, updatedCompany.Relationships[0].Type, models.SubsidiaryOf)
	assert.Equal(t, updatedCompany.Relationships[0].Company, wpp.ID)

	// The inverse relationship is stored on the related company
	updatedWpp, err := mongodb.Companies.GetCompany(wpp.ID)
	assert.NilError(t, err)
	assert.Equal(t, len(updatedWpp.Relationships), 1)
	assert.Equal(t, updatedWpp.Relationships[0].Type, models.ParentOf)
	assert.Equal(t, updatedWpp.Relationships[0].Company, vml.ID)
}

func TestAddCompanyRelationshipMultiple(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	wpp := createRelationshipTestCompany(t, "WPP")
	vml := createRelationshipTestCompany(t, "VML")
	yr := createRelationshipTestCompany(t, "Y&R")

	// A company can absorb several companies, and combine different relationship types
	assert.Equal(t, addRelationshipRequest(t, wpp.ID, models.Absorbed, vml.ID).Code, http.StatusOK)
	assert.Equal(t, addRelationshipRequest(t, wpp.ID, models.Absorbed, yr.ID).Code, http.StatusOK)
	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.RebrandedFrom, yr.ID).Code, http.StatusOK)

	updatedWpp, err := mongodb.Companies.GetCompany(wpp.ID)
	assert.NilError(t, err)
	assert.Equal(t, len(updatedWpp.Relationships), 2)

	updatedYr, err := mongodb.Companies.GetCompany(yr.ID)
	assert.NilError(t, err)
	assert.Equal(t, len(updatedYr.Relationships), 2)
}

func TestAddCompanyRelationshipInvalid(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	wpp := createRelationshipTestCompany(t, "WPP")
	vml := createRelationshipTestCompany(t, "VML")

	// Unknown type
	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.CompanyRelationshipType("SOMETHING"), wpp.ID).Code, http.StatusBadRequest)

	// Related to itself
	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, vml.ID).Code, http.StatusBadRequest)

	// Related company does not exist
	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, primitive.NewObjectID()).Code, http.StatusNotFound)

	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, wpp.ID).Code, http.StatusOK)

	// Duplicated
	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, wpp.ID).Code, http.StatusConflict)

	// Cycle, from both sides
	assert.Equal(t, addRelationshipRequest(t, wpp.ID, models.SubsidiaryOf, vml.ID).Code, http.StatusConflict)
	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.ParentOf, wpp.ID).Code, http.StatusConflict)
}

func TestGetCompanyRelationships(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	wpp := createRelationshipTestCompany(t, "WPP")
	vml := createRelationshipTestCompany(t, "VML")

	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, wpp.ID).Code, http.StatusOK)

	res, err := executeRequest("GET", "/companies/"+wpp.ID.Hex()+"/relationships", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var related []models.RelatedCompany
	json.NewDecoder(res.Body).Decode(&related)

	assert.Equal(t, len(related), 1)
	assert.Equal(t, related[0].Type, models.ParentOf)
	assert.Equal(t, related[0].Company, vml.ID)
	assert.Equal(t, related[0].Name, "VML")

	res, err = executeRequest("GET", "/companies/"+primitive.NewObjectID().Hex()+"/relationships", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestRemoveCompanyRelationship(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	wpp := createRelationshipTestCompany(t, "WPP")
	vml := createRelationshipTestCompany(t, "VML")

	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, wpp.ID).Code, http.StatusOK)

	// Invalid type
	res, err := executeRequest("DELETE", "/companies/"+wpp.ID.Hex()+"/relationships/"+vml.ID.Hex()+"?type=SOMETHING", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	// Removing from the other side also removes the inverse
	res, err = executeRequest("DELETE", "/companies/"+wpp.ID.Hex()+"/relationships/"+vml.ID.Hex()+"?type=PARENT_OF", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	updatedVml, err := mongodb.Companies.GetCompany(vml.ID)
	assert.NilError(t, err)
	assert.Equal(t, len(updatedVml.Relationships), 0)

	// Already removed
	res, err = executeRequest("DELETE", "/companies/"+wpp.ID.Hex()+"/relationships/"+vml.ID.Hex()+"?type=PARENT_OF", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestDeleteCompanyRemovesRelationships(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	wpp := createRelationshipTestCompany(t, "WPP")
	vml := createRelationshipTestCompany(t, "VML")

	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, wpp.ID).Code, http.StatusOK)

	res, err := executeRequest("DELETE", "/companies/"+vml.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	updatedWpp, err := mongodb.Companies.GetCompany(wpp.ID)
	assert.NilError(t, err)
	assert.Equal(t, len(updatedWpp.Relationships), 0)
}

func TestUpdateCompanyRelationship(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	wpp := createRelationshipTestCompany(t, "WPP")
	vml := createRelationshipTestCompany(t, "VML")

	assert.Equal(t, addRelationshipRequest(t, vml.ID, models.SubsidiaryOf, wpp.ID).Code, http.StatusOK)

	since := time.Date(2023, time.October, 1, 0, 0, 0, 0, time.UTC)
	b, errMarshal := json.Marshal(mongodb.UpdateCompanyRelationshipData{Since: &since})
	assert.NilError(t, errMarshal)

	// Updating from the other side also updates the inverse
	res, err := executeRequest("PUT", "/companies/"+wpp.ID.Hex()+"/relationships/"+vml.ID.Hex()+"?type=PARENT_OF", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	updatedWpp, err := mongodb.Companies.GetCompany(wpp.ID)
	assert.NilError(t, err)
	assert.Equal(t, updatedWpp.Relationships[0].Since.Equal(since), true)

	updatedVml, err := mongodb.Companies.GetCompany(vml.ID)
	assert.NilError(t, err)
	assert.Equal(t, updatedVml.Relationships[0].Since.Equal(since), true)

	// A null date removes it from both sides
	res, err = executeRequest("PUT", "/companies/"+vml.ID.Hex()+"/relationships/"+wpp.ID.Hex()+"?type=SUBSIDIARY_OF", bytes.NewBufferString(`{"since": null}`))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	updatedWpp, err = mongodb.Companies.GetCompany(wpp.ID)
	assert.NilError(t, err)
	assert.Assert(t, updatedWpp.Relationships[0].Since == nil)

	updatedVml, err = mongodb.Companies.GetCompany(vml.ID)
	assert.NilError(t, err)
	assert.Assert(t, updatedVml.Relationships[0].Since == nil)

	// Relationship that does not exist
	res, err = executeRequest("PUT", "/companies/"+vml.ID.Hex()+"/relationships/"+wpp.ID.Hex()+"?type=MERGED_INTO", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	// Invalid type
	res, err = executeRequest("PUT", "/companies/"+vml.ID.Hex()+"/relationships/"+wpp.ID.Hex()+"?type=SOMETHING", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestCompanyClosure(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Contacts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	company := createRelationshipTestCompany(t, "Lehman Brothers")

	since := time.Date(2008, time.September, 15, 0, 0, 0, 0, time.UTC)
	closureType := models.Bankrupt
	b, errMarshal := json.Marshal(mongodb.CompanyClosureData{Type: &closureType, Since: &since})
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/companies/"+company.ID.Hex()+"/closure", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var updatedCompany models.Company
	json.NewDecoder(res.Body).Decode(&updatedCompany)

	assert.Assert(t, updatedCompany.Closure != nil)
	assert.Equal(t, updatedCompany.Closure.Type, models.Bankrupt)
	assert.Equal(t, updatedCompany.Closure.Since.Equal(since), true)

	// Invalid type
	res, err = executeRequest("PUT", "/companies/"+company.ID.Hex()+"/closure", bytes.NewBufferString(`{"type": "SOMETHING"}`))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	// Company not found
	res, err = executeRequest("PUT", "/companies/"+primitive.NewObjectID().Hex()+"/closure", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	// Operating again
	res, err = executeRequest("DELETE", "/companies/"+company.ID.Hex()+"/closure", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	updated, err := mongodb.Companies.GetCompany(company.ID)
	assert.NilError(t, err)
	assert.Assert(t, updated.Closure == nil)
}
