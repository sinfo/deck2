package router

import (
	"bytes"
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	//"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	Meeting1	*models.Meeting
	Place1 = "IST"
	Meeting1Data = mongodb.CreateMeetingData{
		Begin : &TimeBefore,
		End:	&TimeAfter,
		Place:	&Place1,
	}
	Meeting2	*models.Meeting
	Place2 = "RNL"
	Begin2 = TimeBefore.Add(-time.Hour * 2)
	End2 = TimeBefore.Add(time.Hour * 2)
	Meeting2Data = mongodb.CreateMeetingData{
		Begin : &Begin2,
		End:	&End2,
		Place:	&Place2,
	}
)

func TestCreateMeeting(t *testing.T){
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	var meeting models.Meeting

	b, errMarshal := json.Marshal(Meeting1Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	Meeting1, err = mongodb.Meetings.GetMeeting(meeting.ID)
	assert.NilError(t, err)

	json.NewDecoder(res.Body).Decode(&meeting)
	assert.Equal(t, meeting.ID, Meeting1.ID)
	assert.Equal(t, meeting.Place, Meeting1.Place)
}

func TestCreateMeetingWithParticipants(t *testing.T){
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

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

	Meeting1, err = mongodb.Meetings.GetMeeting(meeting.ID)
	assert.NilError(t, err)

	json.NewDecoder(res.Body).Decode(&meeting)
	assert.Equal(t, meeting.ID, Meeting1.ID)
	assert.Equal(t, meeting.Place, Meeting1.Place)
	assert.Equal(t, len(meeting.Participants.Members), 1)
	assert.Equal(t, meeting.Participants.Members[0], member)	
}

func TestGetMeeting(t *testing.T){
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	Meeting1, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	var meeting models.Meeting

	res, err := executeRequest("GET", "/meetings/"+Meeting1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&meeting)

	assert.Equal(t, meeting.ID, Meeting1.ID)
}

func TestGetMeetingWrongID(t *testing.T){
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	_, err := mongodb.Meetings.CreateMeeting(Meeting1Data)
	assert.NilError(t, err)

	res, err := executeRequest("GET", "/meetings/wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}