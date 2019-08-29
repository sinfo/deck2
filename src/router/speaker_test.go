package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
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
	Speaker = models.Speaker{Name: "some-name", Bio: "some-bio", Title: "some-title"}
)

func TestCreateSpeaker(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newSpeaker models.Speaker

	createSpeakerData := &mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	b, errMarshal := json.Marshal(createSpeakerData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newSpeaker)

	assert.Equal(t, newSpeaker.Name, Speaker.Name)
	assert.Equal(t, newSpeaker.Bio, Speaker.Bio)
	assert.Equal(t, newSpeaker.Title, Speaker.Title)
}

func TestCreateSpeakerInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	type InvalidPayload struct {
		Name string `json:"name"`
	}

	createSpeakerData := &InvalidPayload{
		Name: Speaker.Name,
	}

	b, errMarshal := json.Marshal(createSpeakerData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetSpeakers(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	var speakers []models.Speaker

	res, err := executeRequest("GET", "/speakers", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&speakers)

	assert.Equal(t, len(speakers) == 1, true)
	assert.Equal(t, speakers[0].ID, newSpeaker.ID)
}

func TestGetSpeaker(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	var speaker models.Speaker

	res, err := executeRequest("GET", "/speakers/"+newSpeaker.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&speaker)

	assert.Equal(t, speaker.ID, newSpeaker.ID)
}

func TestGetSpeakerNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/speakers/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdateSpeaker(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	var newName = "some other name"
	var newBio = "some other bio"
	var newTitle = "some other title"
	var newNotes = "some other notes"

	usd := &mongodb.UpdateSpeakerData{
		Name:  &newName,
		Bio:   &newBio,
		Title: &newTitle,
		Notes: &newNotes,
	}

	b, errMarshal := json.Marshal(usd)
	assert.NilError(t, errMarshal)

	var updatedSpeaker models.Speaker

	res, err := executeRequest("PUT", "/speakers/"+newSpeaker.ID.Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedSpeaker)

	assert.Equal(t, updatedSpeaker.ID, newSpeaker.ID)
	assert.Equal(t, updatedSpeaker.Name, *usd.Name)
	assert.Equal(t, updatedSpeaker.Bio, *usd.Bio)
	assert.Equal(t, updatedSpeaker.Title, *usd.Title)
	assert.Equal(t, updatedSpeaker.Notes, *usd.Notes)
}

func TestUpdateSpeakerInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	type InvalidPayload struct {
		Name string
	}

	usd := &InvalidPayload{
		Name: "some name",
	}

	b, errMarshal := json.Marshal(usd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/speakers/"+newSpeaker.ID.Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateSpeakerNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newName = "some other name"
	var newBio = "some other bio"
	var newTitle = "some other title"
	var newNotes = "some other notes"

	usd := &mongodb.UpdateSpeakerData{
		Name:  &newName,
		Bio:   &newBio,
		Title: &newTitle,
		Notes: &newNotes,
	}

	b, errMarshal := json.Marshal(usd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/companies/"+primitive.NewObjectID().Hex(), bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddSpeakerParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
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

	var updatedSpeaker models.Speaker

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/speakers/"+newSpeaker.ID.Hex()+"/participation", nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedSpeaker)

	assert.Equal(t, updatedSpeaker.ID, newSpeaker.ID)
	assert.Equal(t, len(updatedSpeaker.Participations), 1)
	assert.Equal(t, updatedSpeaker.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedSpeaker.Participations[0].Member, newMember.ID)
}

func TestAddSpeakerParticipationAlreadyIsParticipating(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
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

	_, err = mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/speakers/"+newSpeaker.ID.Hex()+"/participation", nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateSpeakerParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	var feedback = "some feedback"
	var room = models.SpeakerParticipationRoom{
		Type:  "some type",
		Cost:  20,
		Notes: "some notes",
	}

	uspd := &mongodb.UpdateSpeakerParticipationData{
		Member:   &newMember.ID,
		Feedback: &feedback,
		Room:     &room,
	}

	b, errMarshal := json.Marshal(uspd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/speakers/"+newSpeaker.ID.Hex()+"/participation", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedSpeaker)

	assert.Equal(t, updatedSpeaker.ID, newSpeaker.ID)
	assert.Equal(t, len(updatedSpeaker.Participations), 1)
	assert.Equal(t, updatedSpeaker.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedSpeaker.Participations[0].Member, newMember.ID)
	assert.Equal(t, updatedSpeaker.Participations[0].Feedback, feedback)
	assert.Equal(t, updatedSpeaker.Participations[0].Room.Cost, room.Cost)
	assert.Equal(t, updatedSpeaker.Participations[0].Room.Type, room.Type)
	assert.Equal(t, updatedSpeaker.Participations[0].Room.Notes, room.Notes)
}

func TestUpdateSpeakerParticipationInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	_, err = mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	type InvalidPayload struct {
		Member *primitive.ObjectID `json:"member"`
	}

	uspd := &InvalidPayload{
		Member: &newMember.ID,
	}

	b, errMarshal := json.Marshal(uspd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/speakers/"+newSpeaker.ID.Hex()+"/participation", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateSpeakerParticipationNoParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	var feedback = "some feedback"
	var room = models.SpeakerParticipationRoom{
		Type:  "some type",
		Cost:  20,
		Notes: "some notes",
	}

	uspd := &mongodb.UpdateSpeakerParticipationData{
		Member:   &newMember.ID,
		Feedback: &feedback,
		Room:     &room,
	}

	b, errMarshal := json.Marshal(uspd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/speakers/"+newSpeaker.ID.Hex()+"/participation", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusExpectationFailed)
}

func TestUpdateSpeakerParticipationSpeakerNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var feedback = "some feedback"
	var room = models.SpeakerParticipationRoom{
		Type:  "some type",
		Cost:  20,
		Notes: "some notes",
	}

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	uspd := &mongodb.UpdateSpeakerParticipationData{
		Member:   &newMember.ID,
		Feedback: &feedback,
		Room:     &room,
	}

	b, errMarshal := json.Marshal(uspd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/speakers/"+primitive.NewObjectID().Hex()+"/participation", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestListSpeakerValidSteps(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	assert.Equal(t, updatedSpeaker.Participations[0].Status, models.Suggested)

	res, err := executeRequest("GET", "/speakers/"+newSpeaker.ID.Hex()+"/participation/status/next", nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var validSteps validStepsResponse

	json.NewDecoder(res.Body).Decode(&validSteps)

	assert.Equal(t, updatedSpeaker.ID, newSpeaker.ID)
	assert.Equal(t, len(validSteps.Steps) > 0, true)
}

func TestStepSpeakerStatus(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	assert.Equal(t, updatedSpeaker.Participations[0].Status, models.Suggested)

	validSteps, err := mongodb.Speakers.GetSpeakerParticipationStatusValidSteps(newSpeaker.ID)
	assert.NilError(t, err)
	assert.Equal(t, validSteps != nil, true)
	assert.Equal(t, len(*validSteps) > 0, true)

	var step = (*validSteps)[0].Step
	var status = (*validSteps)[0].Next

	res, err := executeRequest("POST", "/speakers/"+newSpeaker.ID.Hex()+"/participation/status/"+strconv.Itoa(step), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedSpeaker)

	assert.Equal(t, updatedSpeaker.ID, newSpeaker.ID)
	assert.Equal(t, len(updatedSpeaker.Participations), 1)
	assert.Equal(t, updatedSpeaker.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedSpeaker.Participations[0].Status, status)
}

func TestSetSpeakerStatus(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	assert.Equal(t, updatedSpeaker.Participations[0].Status, models.Suggested)

	res, err := executeRequest("PUT", "/speakers/"+newSpeaker.ID.Hex()+"/participation/status/"+string(models.Announced), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedSpeaker)

	assert.Equal(t, updatedSpeaker.ID, newSpeaker.ID)
	assert.Equal(t, len(updatedSpeaker.Participations), 1)
	assert.Equal(t, updatedSpeaker.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedSpeaker.Participations[0].Status, models.Announced)
}

func TestSetSpeakerStatusNoParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	res, err := executeRequest("PUT", "/speakers/"+newSpeaker.ID.Hex()+"/participation/status/"+string(models.Announced), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusExpectationFailed)
}

func TestSetSpeakerStatusInvalidCompany(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("PUT", "/speakers/"+primitive.NewObjectID().Hex()+"/participation/status/"+string(models.Announced), nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestSetSpeakerStatusInvalidStatus(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	assert.Equal(t, updatedSpeaker.Participations[0].Status, models.Suggested)

	res, err := executeRequest("PUT", "/companies/"+newSpeaker.ID.Hex()+"/participation/status/someinvalidstatus", nil)

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddSpeakerFlightInfo(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.FlightInfo.Collection.Drop(mongodb.FlightInfo.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	cfid := &mongodb.CreateFlightInfoData{
		Inbound:  &FlightInfo.Inbound,
		Outbound: &FlightInfo.Outbound,
		From:     &FlightInfo.From,
		To:       &FlightInfo.To,
		Link:     FlightInfo.Link,
		Bought:   &FlightInfo.Bought,
		Cost:     &FlightInfo.Cost,
		Notes:    &FlightInfo.Notes,
	}

	b, errMarshal := json.Marshal(cfid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers/"+newSpeaker.ID.Hex()+"/participation/flightInfo", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedSpeaker)

	assert.Equal(t, updatedSpeaker.ID, newSpeaker.ID)
	assert.Equal(t, len(updatedSpeaker.Participations), 1)
	assert.Equal(t, updatedSpeaker.Participations[0].Event, Event1.ID)
	assert.Equal(t, updatedSpeaker.Participations[0].Member, newMember.ID)
	assert.Equal(t, len(updatedSpeaker.Participations[0].Flights), 1)

	createdFlightInfo, err := mongodb.FlightInfo.GetFlightInfo(updatedSpeaker.Participations[0].Flights[0])
	assert.NilError(t, err)

	assert.Equal(t, createdFlightInfo.Inbound.Sub(FlightInfo.Inbound).Seconds() < 10e-3, true)   // millisecond precision
	assert.Equal(t, createdFlightInfo.Outbound.Sub(FlightInfo.Outbound).Seconds() < 10e-3, true) // millisecond precision
	assert.Equal(t, createdFlightInfo.From, FlightInfo.From)
	assert.Equal(t, createdFlightInfo.To, FlightInfo.To)
	assert.Equal(t, createdFlightInfo.Link, FlightInfo.Link)
	assert.Equal(t, createdFlightInfo.Bought, FlightInfo.Bought)
	assert.Equal(t, createdFlightInfo.Cost, FlightInfo.Cost)
	assert.Equal(t, createdFlightInfo.Notes, FlightInfo.Notes)
}

func TestAddSpeakerFlightInfoNoParticipation(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.FlightInfo.Collection.Drop(mongodb.FlightInfo.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cfid := &mongodb.CreateFlightInfoData{
		Inbound:  &FlightInfo.Inbound,
		Outbound: &FlightInfo.Outbound,
		From:     &FlightInfo.From,
		To:       &FlightInfo.To,
		Link:     FlightInfo.Link,
		Bought:   &FlightInfo.Bought,
		Cost:     &FlightInfo.Cost,
		Notes:    &FlightInfo.Notes,
	}

	b, errMarshal := json.Marshal(cfid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers/"+newSpeaker.ID.Hex()+"/participation/flightInfo", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusExpectationFailed)
}

func TestAddSpeakerFlightInfoInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.FlightInfo.Collection.Drop(mongodb.FlightInfo.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name:    "Member",
		Image:   "IMG",
		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	_, err = mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	type InvalidPayload struct {
		Notes string `json:"notes"`
	}

	cfid := &InvalidPayload{
		Notes: FlightInfo.Notes,
	}

	b, errMarshal := json.Marshal(cfid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers/"+newSpeaker.ID.Hex()+"/participation/flightInfo", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddSpeakerFlightInfoNoSpeaker(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.FlightInfo.Collection.Drop(mongodb.FlightInfo.Context)

	mongodb.ResetCurrentEvent()

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	cfid := &mongodb.CreateFlightInfoData{
		Inbound:  &FlightInfo.Inbound,
		Outbound: &FlightInfo.Outbound,
		From:     &FlightInfo.From,
		To:       &FlightInfo.To,
		Link:     FlightInfo.Link,
		Bought:   &FlightInfo.Bought,
		Cost:     &FlightInfo.Cost,
		Notes:    &FlightInfo.Notes,
	}

	b, errMarshal := json.Marshal(cfid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/speakers/"+primitive.NewObjectID().Hex()+"/participation/flightInfo", bytes.NewBuffer(b))

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
