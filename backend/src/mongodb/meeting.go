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
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson"
)

// MeetingsType contains important database information on Meetings
type MeetingsType struct {
	Collection *mongo.Collection
}

// CreateMeetingData contains data needed to create a new meeting
type CreateMeetingData struct {
	Title        *string                     `json:"title" bson:"title"`
	Kind         *string                     `json:"kind" bson:"kind"`
	Begin        *time.Time                  `json:"begin"`
	End          *time.Time                  `json:"end"`
	Place        *string                     `json:"place"`
	Participants *models.MeetingParticipants `json:"participants"` // optional
}

// GetMeetingsOptions contains data that will be used as filters to get meetings
type GetMeetingsOptions struct {
	Event   *int
	Team    *primitive.ObjectID
	Company *primitive.ObjectID
}

// UpdateMeetingData contains data needed to update a new meeting
type UpdateMeetingData struct {
	Title string    `json:"title" bson:"title"`
	Kind  string    `json:"kind" bson:"kind"`
	Begin time.Time `json:"begin" bson:"begin"`
	End   time.Time `json:"end" bson:"end"`
	Place string    `json:"place" bson:"place"`
}

//ParseBody fills an UpdateMeetingData from a body
func (umd *UpdateMeetingData) ParseBody(body io.Reader) error {
	ctx = context.Background()

	if err := json.NewDecoder(body).Decode(umd); err != nil {
		return err
	}
	if len(umd.Place) == 0 {
		return errors.New("invalid place")
	}
	if len(umd.Title) == 0 {
		return errors.New("invalid title")
	}
	var mk = new(models.MeetingKind)
	if err := mk.Parse(umd.Kind); err != nil {
		return errors.New("invalid kind")
	}

	if umd.Begin.After(umd.End) {
		return errors.New("invalid begin and end dates: begin must be before end")
	}

	return nil
}

// Validate the data for meeting creation
func (cmd *CreateMeetingData) Validate() error {
	ctx = context.Background()

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

	if cmd.Title == nil {
		return errors.New("no title given")
	}

	var mk = new(models.MeetingKind)
	if err := mk.Parse(*cmd.Kind); err != nil {
		return errors.New("invalid kind")
	}

	return nil
}

// ParseBody fills the CreateMeetingData from a body
func (cmd *CreateMeetingData) ParseBody(body io.Reader) error {
	ctx = context.Background()

	if err := json.NewDecoder(body).Decode(cmd); err != nil {
		return err
	}

	if err := cmd.Validate(); err != nil {
		return err
	}

	return nil
}

// CreateMeeting creates a meeting.
func (m *MeetingsType) CreateMeeting(data CreateMeetingData) (*models.Meeting, error) {
	ctx = context.Background()

	var meeting models.Meeting

	var c = bson.M{
		"title":          *data.Title,
		"kind":           *data.Kind,
		"begin":          *data.Begin,
		"end":            *data.End,
		"place":          *data.Place,
		"communications": []primitive.ObjectID{},
	}

	if data.Participants != nil {
		c["participants"] = *data.Participants
	}

	insertResult, err := m.Collection.InsertOne(ctx, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := m.Collection.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&meeting); err != nil {
		log.Println("Error creating a meeting:", err)
		return nil, err
	}

	return &meeting, nil
}

// GetMeeting gets a meeting by its ID
func (m *MeetingsType) GetMeeting(meetingID primitive.ObjectID) (*models.Meeting, error) {
	ctx = context.Background()

	var meeting models.Meeting

	err := m.Collection.FindOne(ctx, bson.M{"_id": meetingID}).Decode(&meeting)
	if err != nil {
		return nil, err
	}

	return &meeting, nil
}

// DeleteMeeting removes a meeting by its ID
func (m *MeetingsType) DeleteMeeting(meetingID primitive.ObjectID) (*models.Meeting, error) {
	ctx = context.Background()

	var meeting models.Meeting

	err := m.Collection.FindOne(ctx, bson.M{"_id": meetingID}).Decode(&meeting)
	if err != nil {
		return nil, err
	}

	deleteResult, err := Meetings.Collection.DeleteOne(ctx, bson.M{"_id": meetingID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 meeting, deleted %v", deleteResult.DeletedCount)
	}

	return &meeting, nil
}

// GetMeetings gets teams by event, company, company and event, or team.
func (m *MeetingsType) GetMeetings(data GetMeetingsOptions) ([]*models.Meeting, error) {
	ctx = context.Background()

	var meetings = make([]*models.Meeting, 0)
	var meetingID = make([]primitive.ObjectID, 0)

	// Query functions as an AND. Companies have different participations in diferent events,
	// but not teams
	if data.Team != nil {
		if data.Event != nil || data.Company != nil {
			return meetings, nil
		}

		team, err := Teams.GetTeam(*data.Team)
		if err != nil {
			return nil, err
		}
		meetingID = append(meetingID, team.Meetings...)
	} else if data.Company != nil {
		company, err := Companies.GetCompany(*data.Company)
		if err != nil {
			return nil, err
		}
		if data.Event != nil {
			for _, s := range company.Participations {
				if s.Event == *data.Event {
					for _, t := range s.Communications {
						thread, err := Threads.GetThread(t)
						if err != nil {
							return nil, err
						}
						if thread.Kind == models.ThreadKindMeeting {
							meetingID = append(meetingID, *thread.Meeting)
						}
					}
				}
			}
		} else {
			for _, s := range company.Participations {
				for _, t := range s.Communications {
					thread, err := Threads.GetThread(t)
					if err != nil {
						return nil, err
					}
					if thread.Kind == models.ThreadKindMeeting {
						meetingID = append(meetingID, *thread.Meeting)
					}
				}
			}
		}
	} else if data.Event != nil {
		event, err := Events.GetEvent(*data.Event)
		if err != nil {
			return nil, err
		}
		meetingID = append(meetingID, event.Meetings...)
	} else {
		cur, err := m.Collection.Find(ctx, bson.M{})
		if err != nil {
			return nil, err
		}
		for cur.Next(ctx) {
			var e models.Meeting
			err := cur.Decode(&e)
			if err != nil {
				return nil, err
			}
			meetings = append(meetings, &e)
		}

		if err := cur.Err(); err != nil {
			return nil, err
		}

		cur.Close(ctx)
		return meetings, nil
	}

	for _, s := range meetingID {
		meeting, err := m.GetMeeting(s)
		if err != nil {
			return nil, err
		}
		meetings = append(meetings, meeting)
	}

	return meetings, nil
}

// UpdateMeeting updates a meeting
func (m *MeetingsType) UpdateMeeting(data UpdateMeetingData, meetingID primitive.ObjectID) (*models.Meeting, error) {
	ctx = context.Background()

	var updateQuery = bson.M{
		"$set": bson.M{
			"title": data.Title,
			"kind":  data.Kind,
			"begin": data.Begin,
			"end":   data.End,
			"place": data.Place,
		},
	}

	var filterQuery = bson.M{"_id": meetingID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedMeeting models.Meeting

	if err := m.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedMeeting); err != nil {
		log.Println("error updating meeting:", err)
		return nil, err
	}

	return &updatedMeeting, nil
}

func (m *MeetingsType) UploadMeetingMinute(meetingID primitive.ObjectID, url string) (*models.Meeting, error) {
	var updateQuery = bson.M{
		"$set": bson.M{
			"minute": url,
		},
	}

	var filterQuery = bson.M{"_id": meetingID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedMeeting models.Meeting

	if err := m.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedMeeting); err != nil {
		log.Println("error updating meeting:", err)
		return nil, err
	}

	return &updatedMeeting, nil
}

// AddThread adds a models.Thread to a meeting's list of communications.
func (m *MeetingsType) AddThread(meetingID primitive.ObjectID, threadID primitive.ObjectID) (*models.Meeting, error) {
	ctx := context.Background()

	var updatedMeeting models.Meeting

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"communications": threadID,
		},
	}

	var filterQuery = bson.M{"_id": meetingID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := m.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedMeeting); err != nil {
		log.Println("Error adding communication to meeting:", err)
		return nil, err
	}

	return &updatedMeeting, nil
}

// FindThread finds a thread in a meeting
func (m *MeetingsType) FindThread(threadID primitive.ObjectID) (*models.Meeting, error) {
	ctx := context.Background()
	filter := bson.M{
		"communications": threadID,
	}

	cur, err := m.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	var meeting models.Meeting

	if cur.Next(ctx) {
		if err := cur.Decode(&meeting); err != nil {
			return nil, err
		}
		return &meeting, nil
	}

	return nil, nil
}
