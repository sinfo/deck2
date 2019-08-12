package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"fmt"
	"log"
	"time"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

// MeetingsType contains important database information on Meetings
type MeetingsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// CreateMeetingData contains data needed to create a new meeting
type CreateMeetingData struct {
	Begin        *time.Time                  `json:"begin"`
	End          *time.Time                  `json:"end"`
	Place        *string                     `json:"place"`
	Participants *models.MeetingParticipants `json:"participants"` // optional
}

// GetMeetingsOptions contains data that will be used as filters to get meetings
type GetMeetingsOptions struct {
	Event	*int
	Team	*primitive.ObjectID
	Company	*primitive.ObjectID
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

// GetMeetings gets teams by event, company, company and event, or team.
func (m *MeetingsType) GetMeetings(data GetMeetingsOptions) ([]*models.Meeting, error){
	var meetings = make([]*models.Meeting, 0)
	var meetingID = make([]primitive.ObjectID, 0)

	// Query functions as an AND. Companies have different participations in diferent events,
	// but not teams
	if data.Team != nil {
		if data.Event != nil || data.Company != nil{
			return meetings, nil
		}
		
		team, err := Teams.GetTeam(*data.Team)
		if err != nil{
			return nil, err
		}
		meetingID = append(meetingID,team.Meetings...)
	}

	if data.Company != nil {
		company, err := Companies.GetCompany(*data.Company)
		if err != nil{
			return nil, err
		}
		for _, s := range company.Participations{
			if data.Event != nil{
				if s.Event == *data.Event{
					for _, t := range s.Communications{
						thread, err := Threads.GetThread(t)
						if err != nil{
							return nil, err
						}
						if thread.Kind == models.ThreadKindMeeting{
							meetingID = append(meetingID, *thread.Meeting)
						}
					}
				}
			} else {
				for _, t := range s.Communications{
					thread, err := Threads.GetThread(t)
					if err != nil{
						return nil, err
					}
					if thread.Kind == models.ThreadKindMeeting{
						meetingID = append(meetingID, *thread.Meeting)
					}
				}
			}
		}
	}else{
		if data.Event != nil{
			event, err := Events.GetEvent(*data.Event)
			if err != nil{
				return nil, err
			}
			meetingID =append(meetingID, event.Meetings...)
		}else{
			cur, err := m.Collection.Find(m.Context, bson.M{})
			if err != nil{
				return nil, err
			}
			for cur.Next(m.Context){
				var e models.Meeting
				err := cur.Decode(&e)
				if err != nil{
					return nil, err
				}
				meetings = append(meetings, &e)
			}

			if err := cur.Err(); err != nil {
				return nil, err
			}
		
			cur.Close(m.Context)
		}

		return meetings, nil
	}

	for _, s := range meetingID{
		meeting, err := m.GetMeeting(s)
		if err != nil {
			return nil, err
		}
		meetings = append(meetings, meeting)
	}

	return meetings, nil
}

