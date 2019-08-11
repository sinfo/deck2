package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"time"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

type MeetingsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type CreateMeetingData struct {
	Begin        *time.Time                  `json:"begin"`
	End          *time.Time                  `json:"end"`
	Place        *string                     `json:"place"`
	Participants *models.MeetingParticipants `json:"participants"` // optional
}

// ParseBody fills the CreateItemData from a body
func (cmd *CreateMeetingData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cmd); err != nil {
		return err
	}

	if cmd.Begin == nil {
		return errors.New("no begin date given")
	}

	if cmd.End == nil {
		return errors.New("no end date given")
	}

	if cmd.End.Before(*cmd.Begin) {
		return errors.New("end date must be after the begin date")
	}

	if cmd.Place == nil {
		return errors.New("no place given")
	}

	return nil
}

// CreateMeeting creates a meeting.
func (m *MeetingsType) CreateMeeting(data CreateMeetingData) (*models.Meeting, error) {

	var meeting models.Meeting

	var c = bson.M{
		"begin": *data.Begin,
		"end":   *data.End,
		"place": *data.Place,
	}

	if data.Participants != nil {
		c["participants"] = *data.Participants
	}

	insertResult, err := m.Collection.InsertOne(m.Context, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := m.Collection.FindOne(m.Context, bson.M{"_id": insertResult.InsertedID}).Decode(&meeting); err != nil {
		log.Println("Error creating a meeting:", err)
		return nil, err
	}

	return &meeting, nil
}

// GetMeeting gets a meeting by its ID
func (m *MeetingsType) GetMeeting(meetingID primitive.ObjectID) (*models.Meeting, error) {
	var meeting models.Meeting

	err := m.Collection.FindOne(m.Context, bson.M{"_id": meetingID}).Decode(&meeting)
	if err != nil {
		return nil, err
	}

	return &meeting, nil
}

// DeleteMeeting removes a meeting by its ID
func (m *MeetingsType) DeleteMeeting(meetingID primitive.ObjectID) (*models.Meeting, error) {
	var meeting models.Meeting

	err := m.Collection.FindOne(m.Context, bson.M{"_id": meetingID}).Decode(&meeting)
	if err != nil {
		return nil, err
	}

	deleteResult, err := Meetings.Collection.DeleteOne(m.Context, bson.M{"_id": meetingID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 meeting, deleted %v", deleteResult.DeletedCount)
	}

	return &meeting, nil
}

