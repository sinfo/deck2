package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"testing"
	"time"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"gotest.tools/assert"
)

var (
	Talk = models.Session{
		Begin:       TimeAfter,
		End:         TimeFuture,
		Title:       "talk title",
		Description: "talk description",
		Space:       "talk space",
		Kind:        models.SessionKindTalk,
	}

	Presentation = models.Session{
		Begin:       TimeAfter,
		End:         TimeFuture,
		Title:       "presentation title",
		Description: "presentation description",
		Space:       "presentation space",
		Kind:        models.SessionKindPresentation,
	}
)

type createSessionPayload struct {
	Begin       time.Time          `json:"begin"`
	End         time.Time          `json:"end"`
	Title       string             `json:"title"`
	Description string             `json:"description"`
	Space       string             `json:"space"`
	Kind        string             `json:"kind"`
	Company     primitive.ObjectID `json:"company"`
	Speaker     primitive.ObjectID `json:"speaker"`
}

func TestCreateSession(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Sessions.Collection.Drop(mongodb.Sessions.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	kind := string(Talk.Kind)

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	updatedSpeaker, err = mongodb.Speakers.UpdateSpeakerParticipationStatus(updatedSpeaker.ID, models.Announced)
	assert.NilError(t, err)

	csd := createSessionPayload{
		Begin:       Talk.Begin,
		End:         Talk.End,
		Title:       Talk.Title,
		Description: Talk.Description,
		Space:       Talk.Space,
		Kind:        kind,
		Speaker:     updatedSpeaker.ID,
	}

	b, errMarshal := json.Marshal(csd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events/sessions", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var newEvent models.Event

	json.NewDecoder(res.Body).Decode(&newEvent)
	assert.NilError(t, err)

	assert.Equal(t, len(newEvent.Sessions) == 1, true)

	newSession, err := mongodb.Sessions.GetSession(newEvent.Sessions[0])

	assert.Equal(t, newSession.Begin.Sub(Talk.Begin).Seconds() < 10e-3, true) // millisecond precision
	assert.Equal(t, newSession.End.Sub(Talk.End).Seconds() < 10e-3, true)     // millisecond precision
	assert.Equal(t, newSession.Title, Talk.Title)
	assert.Equal(t, newSession.Description, Talk.Description)
	assert.Equal(t, newSession.Space, Talk.Space)
	assert.Equal(t, newSession.Kind, Talk.Kind)
	assert.Equal(t, *newSession.Speaker, newSpeaker.ID)
}

func TestCreateSessionBadPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Sessions.Collection.Drop(mongodb.Sessions.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

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
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	updatedSpeaker, err = mongodb.Speakers.UpdateSpeakerParticipationStatus(updatedSpeaker.ID, models.Announced)
	assert.NilError(t, err)

	type BadPayload struct{}

	csd := BadPayload{}

	b, errMarshal := json.Marshal(csd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events/sessions", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetSession(t *testing.T) {
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Sessions.Collection.Drop(mongodb.Sessions.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	kind := string(Talk.Kind)

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	updatedSpeaker, err = mongodb.Speakers.UpdateSpeakerParticipationStatus(updatedSpeaker.ID, models.Announced)
	assert.NilError(t, err)

	csd := mongodb.CreateSessionData{
		Begin:       &Talk.Begin,
		End:         &Talk.End,
		Title:       &Talk.Title,
		Description: &Talk.Description,
		Space:       &Talk.Space,
		Kind:        &kind,
		Speaker:     &updatedSpeaker.ID,
	}

	newSession, err := mongodb.Sessions.CreateSession(csd)
	assert.NilError(t, err)

	res, err := executeRequest("GET", "/sessions/"+newSession.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var session models.Session
	json.NewDecoder(res.Body).Decode(&session)

	assert.Equal(t, newSession.ID, session.ID)
}

func TestGetSessionNotFound(t *testing.T) {
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Sessions.Collection.Drop(mongodb.Sessions.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/sessions/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestGetSessions(t *testing.T) {
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Sessions.Collection.Drop(mongodb.Sessions.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	kind := string(Talk.Kind)

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	updatedSpeaker, err = mongodb.Speakers.UpdateSpeakerParticipationStatus(updatedSpeaker.ID, models.Announced)
	assert.NilError(t, err)

	csd := mongodb.CreateSessionData{
		Begin:       &Talk.Begin,
		End:         &Talk.End,
		Title:       &Talk.Title,
		Description: &Talk.Description,
		Space:       &Talk.Space,
		Kind:        &kind,
		Speaker:     &updatedSpeaker.ID,
	}

	newSession, err := mongodb.Sessions.CreateSession(csd)
	assert.NilError(t, err)

	event, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	_, err = mongodb.Events.AddSession(event.ID, newSession.ID)
	assert.NilError(t, err)

	res, err := executeRequest("GET", "/sessions", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var sessions []models.Session
	json.NewDecoder(res.Body).Decode(&sessions)

	assert.Equal(t, len(sessions), 1)

	session := sessions[0]

	assert.Equal(t, newSession.ID, session.ID)
}

func TestUpdateSession(t *testing.T) {
	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Sessions.Collection.Drop(mongodb.Sessions.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)
	defer mongodb.Speakers.Collection.Drop(mongodb.Speakers.Context)
	defer mongodb.Companies.Collection.Drop(mongodb.Companies.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	kind := string(Talk.Kind)

	createSpeakerData := mongodb.CreateSpeakerData{
		Name:  &Speaker.Name,
		Bio:   &Speaker.Bio,
		Title: &Speaker.Title,
	}

	newSpeaker, err := mongodb.Speakers.CreateSpeaker(createSpeakerData)
	assert.NilError(t, err)

	createCompanyData := mongodb.CreateCompanyData{
		Name:        &Company.Name,
		Description: &Company.Description,
		Site:        &Company.Site,
	}

	newCompany, err := mongodb.Companies.CreateCompany(createCompanyData)
	assert.NilError(t, err)

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	updatedSpeaker, err := mongodb.Speakers.AddParticipation(newSpeaker.ID, newMember.ID)
	assert.NilError(t, err)

	updatedSpeaker, err = mongodb.Speakers.UpdateSpeakerParticipationStatus(updatedSpeaker.ID, models.Announced)
	assert.NilError(t, err)

	updatedCompany, err := mongodb.Companies.AddParticipation(newCompany.ID, newMember.ID, mongodb.AddParticipationData{Partner: true})
	assert.NilError(t, err)

	updatedCompany, err = mongodb.Companies.UpdateCompanyParticipationStatus(updatedCompany.ID, models.Announced)
	assert.NilError(t, err)

	csd := mongodb.CreateSessionData{
		Begin:       &Talk.Begin,
		End:         &Talk.End,
		Title:       &Talk.Title,
		Description: &Talk.Description,
		Space:       &Talk.Space,
		Kind:        &kind,
		Speaker:     &updatedSpeaker.ID,
	}

	newSession, err := mongodb.Sessions.CreateSession(csd)
	assert.NilError(t, err)

	event, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	_, err = mongodb.Events.AddSession(event.ID, newSession.ID)
	assert.NilError(t, err)

	usd := &createSessionPayload{
		Begin:       Presentation.Begin,
		End:         Presentation.End,
		Title:       Presentation.Title,
		Description: Presentation.Description,
		Space:       Presentation.Space,
		Kind:        string(Presentation.Kind),
		Company:     updatedCompany.ID,
	}

	b, errMarshal := json.Marshal(usd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/sessions/"+newSession.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var updatedSession models.Session

	json.NewDecoder(res.Body).Decode(&updatedSession)
	assert.NilError(t, err)

	assert.Equal(t, updatedSession.Begin.Sub(Presentation.Begin).Seconds() < 10e-3, true) // millisecond precision
	assert.Equal(t, updatedSession.End.Sub(Presentation.End).Seconds() < 10e-3, true)     // millisecond precision
	assert.Equal(t, updatedSession.Title, Presentation.Title)
	assert.Equal(t, updatedSession.Description, Presentation.Description)
	assert.Equal(t, updatedSession.Space, Presentation.Space)
	assert.Equal(t, updatedSession.Kind, Presentation.Kind)
	assert.Equal(t, *updatedSession.Company, newCompany.ID)
}
