package router

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	Meeting1     *models.Meeting
	Place1       = "IST"
	Meeting1Data = mongodb.CreateMeetingData{
		Begin: &TimeBefore,
		End:   &TimeAfter,
		Place: &Place1,
	}
	Meeting2     *models.Meeting
	Place2       = "RNL"
	Begin2       = TimeBefore.Add(-time.Hour * 2)
	End2         = TimeBefore.Add(time.Hour * 2)
	Meeting2Data = mongodb.CreateMeetingData{
		Begin: &Begin2,
		End:   &End2,
		Place: &Place2,
	}
)

func TestCreateMeeting(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	var meeting models.Meeting

	b, errMarshal := json.Marshal(Meeting1Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meeting)

	Meeting1, err = mongodb.Meetings.GetMeeting(meeting.ID)
	assert.NilError(t, err)

	assert.Equal(t, meeting.ID, Meeting1.ID)
	assert.Equal(t, meeting.Place, Meeting1.Place)
}

func TestCreateMeetingWithParticipants(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	var member = primitive.NewObjectID()
	var participants = models.MeetingParticipants{
		Members: append(make([]primitive.ObjectID, 0), member),
	}

	Meeting1Data.Participants = &participants

	var meeting models.Meeting

	b, errMarshal := json.Marshal(Meeting1Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meeting)

	Meeting1, err = mongodb.Meetings.GetMeeting(meeting.ID)
	assert.NilError(t, err)

	assert.Equal(t, meeting.ID, Meeting1.ID)
	assert.Equal(t, meeting.Place, Meeting1.Place)
	assert.Equal(t, len(meeting.Participants.Members), 1)
	assert.Equal(t, meeting.Participants.Members[0], member)
}

func TestCreateMeetingBadPayload(t *testing.T) {

	var BadData1 = mongodb.CreateMeetingData{
		End:   &TimeAfter,
		Place: &Place1,
	}
	var BadData2 = mongodb.CreateMeetingData{
		Begin: &TimeBefore,
		Place: &Place1,
	}
	var BadData3 = mongodb.CreateMeetingData{
		Begin: &TimeBefore,
		End:   &TimeAfter,
	}
	var BadData4 = mongodb.CreateMeetingData{
		Begin: &TimeAfter,
		End:   &TimeBefore,
		Place: &Place1,
	}

	b, errMarshal := json.Marshal(BadData1)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	b, errMarshal = json.Marshal(BadData2)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	b, errMarshal = json.Marshal(BadData3)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	b, errMarshal = json.Marshal(BadData4)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetMeeting(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	var meeting models.Meeting

	res, err := executeRequest("GET", "/meetings/"+Meeting1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meeting)

	assert.Equal(t, meeting.ID, Meeting1.ID)
}

func TestGetMeetingWrongID(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	_, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	res, err := executeRequest("GET", "/meetings/wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestDeleteMeeting(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	var meeting models.Meeting

	res, err := executeRequest("DELETE", "/meetings/"+Meeting1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meeting)

	assert.Equal(t, meeting.ID, Meeting1.ID)

	res, err = executeRequest("GET", "/meetings/"+Meeting1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestGetMeetings(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	var meetings []*models.Meeting

	res, err := executeRequest("GET", "/meetings", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meetings)

	assert.Equal(t, len(meetings), 1)
	assert.Equal(t, meetings[0].ID, Meeting1.ID)
}

func TestGetMeetingsEvent(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)

	//Setup
	_, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": 1, "name": "SINFO1"})

	if err != nil {
		log.Fatal(err)
	}
	ced := mongodb.CreateEventData{
		Name: "SINFO2",
	}
	event, err := mongodb.Events.CreateEvent(ced)
	if err != nil {
		log.Fatal(err)
	}

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	_, err = mongodb.Meetings.CreateMeeting(Meeting2Data)
	assert.NilError(t, err)

	event, err = mongodb.Events.AddMeeting(event.ID, Meeting1.ID)
	assert.NilError(t, err)

	// End setup

	var meetings []*models.Meeting

	var query = "?event=" + url.QueryEscape(strconv.Itoa(event.ID))
	res, err := executeRequest("GET", "/meetings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meetings)

	assert.Equal(t, len(meetings), 1)
	assert.Equal(t, meetings[0].ID, Meeting1.ID)
}

func TestGetMeetingsTeam(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)

	//Setup
	_, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": 1, "name": "SINFO1"})

	if err != nil {
		log.Fatal(err)
	}
	ced := mongodb.CreateEventData{
		Name: "SINFO2",
	}
	_, err = mongodb.Events.CreateEvent(ced)
	if err != nil {
		log.Fatal(err)
	}

	var ctd = mongodb.CreateTeamData{
		Name: "TEAM1",
	}

	Team1, err := mongodb.Teams.CreateTeam(ctd)
	if err != nil {
		log.Fatal(err)
	}

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	_, err = mongodb.Meetings.CreateMeeting(Meeting2Data)
	assert.NilError(t, err)

	Team1, err = mongodb.Teams.AddMeeting(Team1.ID, Meeting1.ID)
	assert.NilError(t, err)

	// End setup

	var meetings []*models.Meeting

	var query = "?team=" + url.QueryEscape(Team1.ID.Hex())
	res, err := executeRequest("GET", "/meetings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meetings)

	assert.Equal(t, len(meetings), 1)
	assert.Equal(t, meetings[0].ID, Meeting1.ID)
}

func TestGetMeetingsCompany(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	//Setup
	_, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": 1, "name": "SINFO1"})

	if err != nil {
		log.Fatal(err)
	}
	ced := mongodb.CreateEventData{
		Name: "SINFO2",
	}
	_, err = mongodb.Events.CreateEvent(ced)
	if err != nil {
		log.Fatal(err)
	}

	var name = "COMPANY1"
	var description = "Cool Company"
	var site = "www.company.com"

	var ccd = mongodb.CreateCompanyData{
		Name:        &name,
		Description: &description,
		Site:        &site,
	}

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	assert.NilError(t, err)

	company, err := mongodb.Companies.CreateCompany(ccd)
	assert.NilError(t, err)

	var apd = mongodb.AddParticipationData{
		Partner: true,
	}

	company, err = mongodb.Companies.AddParticipation(company.ID, Member1.ID, apd)
	assert.NilError(t, err)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	_, err = mongodb.Meetings.CreateMeeting(Meeting2Data)
	assert.NilError(t, err)

	var ctd = mongodb.CreateThreadData{
		Meeting: &Meeting1.ID,
		Kind:    models.ThreadKindMeeting,
	}

	thread, err := mongodb.Threads.CreateThread(ctd)
	assert.NilError(t, err)

	company, err = mongodb.Companies.AddThread(company.ID, thread.ID)
	assert.NilError(t, err)

	// End setup

	var meetings []*models.Meeting

	var query = "?company=" + url.QueryEscape(company.ID.Hex())
	res, err := executeRequest("GET", "/meetings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meetings)

	assert.Equal(t, len(meetings), 1)
	assert.Equal(t, meetings[0].ID, Meeting1.ID)
}

func TestGetMeetingsEventCompany(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Companies.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	//Setup
	_, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": 1, "name": "SINFO1"})

	if err != nil {
		log.Fatal(err)
	}
	ced := mongodb.CreateEventData{
		Name: "SINFO2",
	}
	event, err := mongodb.Events.CreateEvent(ced)
	if err != nil {
		log.Fatal(err)
	}

	var id = strconv.Itoa(event.ID)

	var name = "COMPANY1"
	var description = "Cool Company"
	var site = "www.company.com"

	var ccd = mongodb.CreateCompanyData{
		Name:        &name,
		Description: &description,
		Site:        &site,
	}

	company, err := mongodb.Companies.CreateCompany(ccd)
	assert.NilError(t, err)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	assert.NilError(t, err)

	var apd = mongodb.AddParticipationData{
		Partner: true,
	}

	company, err = mongodb.Companies.AddParticipation(company.ID, Member1.ID, apd)
	assert.NilError(t, err)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	_, err = mongodb.Meetings.CreateMeeting(Meeting2Data)
	assert.NilError(t, err)

	var ctd = mongodb.CreateThreadData{
		Meeting: &Meeting1.ID,
		Kind:    models.ThreadKindMeeting,
	}

	thread, err := mongodb.Threads.CreateThread(ctd)
	assert.NilError(t, err)

	company, err = mongodb.Companies.AddThread(company.ID, thread.ID)
	assert.NilError(t, err)

	ced = mongodb.CreateEventData{
		Name: "SINFO3",
	}
	_, err = mongodb.Events.CreateEvent(ced)
	if err != nil {
		log.Fatal(err)
	}

	// End setup

	var meetings []*models.Meeting

	var query = "?company=" + url.QueryEscape(company.ID.Hex()) + "&event=" + url.QueryEscape(id)
	res, err := executeRequest("GET", "/meetings"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meetings)

	assert.Equal(t, len(meetings), 1)
	assert.Equal(t, meetings[0].ID, Meeting1.ID)
}

func TestUpdateMeeting(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	var timeNow = time.Now()
	var newBefore = timeNow.Add(time.Hour * -24)
	var newAfter = timeNow.Add(time.Hour * 24)
	var place = "NEW PLACE"
	var minute = "NEW MINUTE"

	var umd = mongodb.UpdateMeetingData{
		Begin:  newBefore,
		End:    newAfter,
		Place:  place,
		Minute: minute,
	}

	var meeting models.Meeting

	b, errMarshal := json.Marshal(umd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/meetings/"+Meeting1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meeting)

	assert.Equal(t, meeting.ID, Meeting1.ID)
	assert.Equal(t, meeting.Place, place)
	assert.Equal(t, meeting.Begin.Sub(newBefore).Seconds() < 10e-3, true)
	assert.Equal(t, meeting.End.Sub(newAfter).Seconds() < 10e-3, true)
}

func TestUpdateMeetingBadDate(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	var timeNow = time.Now()
	var newBefore = timeNow.Add(time.Hour * -24)
	var newAfter = timeNow.Add(time.Hour * 24)
	var place = "NEW PLACE"
	var minute = "NEW MINUTE"

	var umd = mongodb.UpdateMeetingData{
		Begin:  newAfter,
		End:    newBefore,
		Place:  place,
		Minute: minute,
	}

	b, errMarshal := json.Marshal(umd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/meetings/"+Meeting1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateMeetingBadPlace(t *testing.T) {
	ctx := context.Background()
	defer mongodb.Meetings.Collection.Drop(ctx)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	var timeNow = time.Now()
	var newBefore = timeNow.Add(time.Hour * -24)
	var newAfter = timeNow.Add(time.Hour * 24)
	var minute = "NEW MINUTE"

	var umd = mongodb.UpdateMeetingData{
		Begin:  newBefore,
		End:    newAfter,
		Place:  "",
		Minute: minute,
	}

	b, errMarshal := json.Marshal(umd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/meetings/"+Meeting1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateMeetingNotFound(t *testing.T) {

	res, err := executeRequest("PUT", "/meetings/wrong", bytes.NewBuffer([]byte{}))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
