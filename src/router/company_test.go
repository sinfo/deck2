package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"testing"

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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

func TestAddCompanyParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

func TestAddCompanyThread(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("POST", "/companies/"+primitive.NewObjectID().Hex()+"/thread", bytes.NewBuffer([]byte{}))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddCompanyThreadNoParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	createdPackage, err := mongodb.Packages.GetPackage(packageID)
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	packages, err := mongodb.Packages.GetPackages()
	assert.NilError(t, err)
	assert.Equal(t, len(packages), 0)
}
func TestAddCompanyPackageNoParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
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

	packages, err := mongodb.Packages.GetPackages()
	assert.NilError(t, err)
	assert.Equal(t, len(packages), 0)
}
