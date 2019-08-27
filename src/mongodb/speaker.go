package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type SpeakersType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type CreateSpeakerData struct {
	Name  *string `json:"name"`
	Title *string `json:"title"`
	Bio   *string `json:"bio"`
}

// ParseBody fills the CreateSpeakerData from a body
func (cpd *CreateSpeakerData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cpd); err != nil {
		return err
	}

	if cpd.Name == nil || len(*cpd.Name) == 0 {
		return errors.New("invalid name")
	}

	if cpd.Title == nil {
		return errors.New("invalid title")
	}

	if cpd.Bio == nil {
		return errors.New("invalid bio")
	}

	return nil
}

// CreateSpeaker creates a new speaker and saves it to the database
func (s *SpeakersType) CreateSpeaker(data CreateSpeakerData) (*models.Speaker, error) {

	insertResult, err := s.Collection.InsertOne(s.Context, bson.M{
		"name":           data.Name,
		"title":          data.Title,
		"bio":            data.Bio,
		"participations": []models.SpeakerParticipation{},
	})

	if err != nil {
		return nil, err
	}

	newSpeaker, err := s.GetSpeaker(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created speaker", err)
		return nil, err
	}

	return newSpeaker, nil
}

// GetSpeakersOptions is the options to give to GetSpeakers.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetSpeakersOptions struct {
	EventID  *int
	MemberID *primitive.ObjectID
	Name     *string
}

// GetSpeakers gets all speakers specified with a query
func (s *SpeakersType) GetSpeakers(options GetSpeakersOptions) ([]*models.Speaker, error) {
	var speakers = make([]*models.Speaker, 0)

	filter := bson.M{}

	if options.EventID != nil {
		filter["participations.event"] = options.EventID
	}

	if options.MemberID != nil {
		filter["participations.member"] = options.MemberID
	}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	cur, err := s.Collection.Find(s.Context, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(s.Context) {

		// create a value into which the single document can be decoded
		var s models.Speaker
		err := cur.Decode(&s)
		if err != nil {
			return nil, err
		}

		speakers = append(speakers, &s)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(s.Context)

	return speakers, nil
}

// GetSpeaker gets a speaker by its ID.
func (s *SpeakersType) GetSpeaker(speakerID primitive.ObjectID) (*models.Speaker, error) {
	var speaker models.Speaker

	err := s.Collection.FindOne(s.Context, bson.M{"_id": speakerID}).Decode(&speaker)
	if err != nil {
		return nil, err
	}

	return &speaker, nil
}
