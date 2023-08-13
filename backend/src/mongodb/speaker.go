package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

//SpeakersType contains database information on speakers
type SpeakersType struct {
	Collection *mongo.Collection
}

// Cached version of the public speakers for the current event
var currentPublicSpeakers *[]*models.SpeakerPublic

//ResetCurrentPublicSpeakers resets current public speakers
func ResetCurrentPublicSpeakers() {
	currentPublicSpeakers = nil
}

func speakerToPublic(speaker models.Speaker, eventID *int) (*models.SpeakerPublic, error) {

	public := models.SpeakerPublic{
		ID:    speaker.ID,
		Name:  speaker.Name,
		Title: speaker.Title,
		Images: models.SpeakerImagesPublic{
			Speaker: speaker.Images.Speaker,
			Company: speaker.Images.Company,
		},
		Participations: make([]models.SpeakerParticipationPublic, 0),
	}

	var participation *models.SpeakerParticipation

	for _, p := range speaker.Participations {

		if eventID == nil && p.Status == models.Announced {
			participation = &p
		} else if eventID != nil {
			if p.Event == *eventID {

				if p.Status != models.Announced {
					return nil, fmt.Errorf("speaker not announced on event %d", eventID)
				}

				participation = &p
			}
		}

		if participation != nil {
			public.Participations = append(public.Participations, models.SpeakerParticipationPublic{
				Event:    participation.Event,
				Feedback: participation.Feedback,
			})
		}
	}

	return &public, nil
}

//CreateSpeakerData holds data needed to create a speaker
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
	ctx := context.Background()

	createdContact, err := Contacts.Collection.InsertOne(ctx, bson.M{
		"phones": []models.ContactPhone{},
		"socials": bson.M{
			"facebook": "",
			"skype":    "",
			"github":   "",
			"twitter":  "",
			"linkedin": "",
		},
		"mails": []models.ContactMail{},
	})

	if err != nil {
		return nil, err
	}

	insertResult, err := s.Collection.InsertOne(ctx, bson.M{
		"name":           data.Name,
		"title":          data.Title,
		"bio":            data.Bio,
		"participations": []models.SpeakerParticipation{},
		"contact":        createdContact.InsertedID.(primitive.ObjectID),
	})

	if err != nil {
		return nil, err
	}

	newSpeaker, err := s.GetSpeaker(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created speaker", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return newSpeaker, nil
}

// GetSpeakersOptions is the options to give to GetSpeakers.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetSpeakersOptions struct {
	EventID            *int
	MemberID           *primitive.ObjectID
	Name               *string
	NumRequests        *int64
	MaxSpeaksInRequest *int64
	SortingMethod      *string
}

// GetSpeakers gets all speakers specified with a query
func (s *SpeakersType) GetSpeakers(speakOptions GetSpeakersOptions) ([]*models.Speaker, error) {
	ctx := context.Background()
	var speakers = make([]*models.Speaker, 0)

	filter := bson.M{}
	elemMatch := bson.M{}

	findOptions := options.Find()

	if speakOptions.EventID != nil {
		elemMatch["event"] = speakOptions.EventID
	}

	if speakOptions.MemberID != nil {
		elemMatch["member"] = speakOptions.MemberID
	}

	if speakOptions.EventID != nil || speakOptions.MemberID != nil {
		filter["participations"] = bson.M{
			"$elemMatch": elemMatch,
		}
	}

	if speakOptions.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *speakOptions.Name),
			"$options": "i",
		}
	}

	if speakOptions.MaxSpeaksInRequest != nil && speakOptions.SortingMethod == nil {
		findOptions.SetLimit(*speakOptions.MaxSpeaksInRequest)
	}

	if speakOptions.NumRequests != nil && speakOptions.SortingMethod == nil {
		findOptions.SetSkip(*speakOptions.NumRequests * (*speakOptions.MaxSpeaksInRequest))
	}

	var err error
	var cur *mongo.Cursor
	if speakOptions.SortingMethod != nil {
		switch *speakOptions.SortingMethod {
		case string(NumberParticipations):
			query := mongo.Pipeline{
				{
					{Key: "$match", Value: filter},
				},
				{
					{Key: "$addFields", Value: bson.D{
						{Key: "numParticipations", Value: bson.D{
							{Key: "$size", Value: bson.D{
								{Key: "$filter", Value: bson.D{
									{Key: "input", Value: "$participations"},
									{Key: "as", Value: "participation"},
									{Key: "cond", Value: bson.D{
										{Key: "$eq", Value: bson.A{
											"$$participation.status", "ANNOUNCED",
										}},
									}},
								}},
							}},
						}},
					}},
				},
				{
					{Key: "$sort", Value: bson.D{
						{Key: "numParticipations", Value: -1},
					}},
				},
				{
					{Key: "$skip", Value: (*speakOptions.NumRequests * (*speakOptions.MaxSpeaksInRequest))},
				},
				{
					{Key: "$limit", Value: *speakOptions.MaxSpeaksInRequest},
				},
			}
			cur, err = s.Collection.Aggregate(ctx, query)
			if err != nil {
				return nil, err
			}
			break
		case string(LastParticipation):
			query := mongo.Pipeline{
				{
					{Key: "$match", Value: filter},
				},
				{
					{Key: "$addFields", Value: bson.D{
						{Key: "participationsAnnounced", Value: bson.D{
							{Key: "$filter", Value: bson.D{
								{Key: "input", Value: "$participations"},
								{Key: "as", Value: "participation"},
								{Key: "cond", Value: bson.D{
									{Key: "$eq", Value: bson.A{
										"$$participation.status", "ANNOUNCED",
									}},
								}},
							}},
						}},
					}},
				},
				{
					{Key: "$sort", Value: bson.D{
						{Key: "participationsAnnounced.event", Value: -1},
					}},
				},
				{
					{Key: "$skip", Value: (*speakOptions.NumRequests * (*speakOptions.MaxSpeaksInRequest))},
				},
				{
					{Key: "$limit", Value: *speakOptions.MaxSpeaksInRequest},
				},
			}
			cur, err = s.Collection.Aggregate(ctx, query)
			if err != nil {
				return nil, err
			}
			break
		default:
			return nil, errors.New("error parsing Sorting Method")
		}
	} else {
		cur, err = s.Collection.Find(ctx, filter, findOptions)
		if err != nil {
			return nil, err
		}
	}

	for cur.Next(ctx) {

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

	cur.Close(ctx)

	return speakers, nil
}

// GetSpeakersPublicOptions is the options to give to GetCompanies.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetSpeakersPublicOptions struct {
	EventID *int
	Name    *string
}

// GetPublicSpeakers gets all companies specified with a query to be shown publicly
func (s *SpeakersType) GetPublicSpeakers(options GetSpeakersPublicOptions) ([]*models.SpeakerPublic, error) {
	ctx := context.Background()

	var public = make([]*models.SpeakerPublic, 0)
	var eventID int

	filter := bson.M{}

	if options.EventID == nil && options.Name == nil && currentPublicSpeakers != nil {

		// return cached value
		return *currentPublicSpeakers, nil
	}

	if options.EventID != nil {

		filter["participations.event"] = options.EventID
		eventID = *options.EventID

	} else {

		currentEvent, err := Events.GetCurrentEvent()
		if err != nil {
			return public, errors.New("error getting the current event")
		}

		filter["participations.event"] = currentEvent.ID
		eventID = currentEvent.ID
	}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	cur, err := s.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {

		// create a value into which the single document can be decoded
		var c models.Speaker
		err := cur.Decode(&c)
		if err != nil {
			return nil, err
		}

		p, err := speakerToPublic(c, &eventID)
		if err == nil {
			public = append(public, p)
		}

	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(ctx)

	// update cached value
	if options.EventID == nil && options.Name == nil && currentPublicSpeakers == nil {
		currentPublicSpeakers = &public
	}

	return public, nil
}

// GetSpeaker gets a speaker by its ID.
func (s *SpeakersType) GetSpeaker(speakerID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()
	var speaker models.Speaker

	err := s.Collection.FindOne(ctx, bson.M{"_id": speakerID}).Decode(&speaker)
	if err != nil {
		return nil, err
	}

	return &speaker, nil
}

// DeleteSpeaker deletes a speaker (public) by its ID.
func (s *SpeakersType) DeleteSpeaker(speakerID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	var speaker models.Speaker

  currentSpeaker, err := s.GetSpeaker(speakerID)
  if err != nil {
    return nil, err
  }

  if len(currentSpeaker.Participations) > 0 {
    return nil, errors.New("Speaker has participations, cannot delete")
  }

	err = s.Collection.FindOneAndDelete(ctx, bson.M{"_id": speakerID}).Decode(&speaker)
	if err != nil {
		return nil, err
	}

  _, err = Contacts.DeleteContact(*speaker.Contact)
  if err != nil {
    return nil, err
  }

	return &speaker, nil
}

// GetSpeakerPublic gets a speaker (public) by its ID.
func (s *SpeakersType) GetSpeakerPublic(speakerID primitive.ObjectID) (*models.SpeakerPublic, error) {
	ctx := context.Background()
	var speaker models.Speaker

	err := s.Collection.FindOne(ctx, bson.M{"_id": speakerID}).Decode(&speaker)
	if err != nil {
		return nil, err
	}

	public, err := speakerToPublic(speaker, nil)
	if err != nil {
		return nil, err
	}

	return public, nil
}

// UpdateSpeakerData is the data used to update a speaker, using the method UpdateSpeaker.
type UpdateSpeakerData struct {
	Name  *string
	Bio   *string
	Title *string
	Notes *string
}

// ParseBody fills the UpdateSpeakerData from a body
func (usd *UpdateSpeakerData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(usd); err != nil {
		return err
	}

	return nil
}

// UpdateSpeaker updates the general information about a speaker, unrelated to other data types stored in de database.
func (s *SpeakersType) UpdateSpeaker(speakerID primitive.ObjectID, data UpdateSpeakerData) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	updateFields := bson.M{}

	if data.Name != nil {
		updateFields["name"] = *data.Name
	}
	if data.Bio != nil {
		updateFields["bio"] = *data.Bio
	}
	if data.Title != nil {
		updateFields["title"] = *data.Title
	}
	if data.Notes != nil {
		updateFields["notes"] = *data.Notes
	}

	var updateQuery = bson.M{
		"$set": updateFields,
	}

	var filterQuery = bson.M{"_id": speakerID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("error updating speaker:", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return &updatedSpeaker, nil
}

// Subscribe a user to the current speaker's participation
func (s *SpeakersType) Subscribe(speakerID primitive.ObjectID, memberID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var filterQuery = bson.M{
		"_id":                  speakerID,
		"participations.event": currentEvent.ID,
	}

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations.$.subscribers": memberID,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error finding updated speaker:", err)
		return nil, err
	}

	return &updatedSpeaker, nil
}

// Unsubscribe a user to the current speaker's participation
func (s *SpeakersType) Unsubscribe(speakerID primitive.ObjectID, memberID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var filterQuery = bson.M{
		"_id":                  speakerID,
		"participations.event": currentEvent.ID,
	}

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations.$.subscribers": memberID,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error finding updated speaker:", err)
		return nil, err
	}

	return &updatedSpeaker, nil
}

// AddParticipation adds a participation on the current event to the speaker with the indicated id.
func (s *SpeakersType) AddParticipation(speakerID primitive.ObjectID, memberID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedSpeaker models.Speaker

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations": bson.M{
				"event":          currentEvent.ID,
				"member":         memberID,
				"status":         models.Suggested,
				"communications": []primitive.ObjectID{},
				"flights":        []primitive.ObjectID{},
				"subscribers":    []primitive.ObjectID{memberID},
			},
		},
	}

	var filterQuery = bson.M{"_id": speakerID, "participations.event": bson.M{"$ne": currentEvent.ID}}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error finding created speaker:", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return &updatedSpeaker, nil
}

//UpdateSpeakerParticipationData holds data needed to update a speakers' participation
type UpdateSpeakerParticipationData struct {
	Member   *primitive.ObjectID              `json:"member"`
	Feedback *string                          `json:"feedback"`
	Room     *models.SpeakerParticipationRoom `json:"room"`
}

// ParseBody fills the UpdateSpeakerParticipationData from a body
func (uspd *UpdateSpeakerParticipationData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(uspd); err != nil {
		return err
	}

	if uspd.Member == nil {
		return errors.New("invalid member ID")
	}

	if uspd.Feedback == nil {
		return errors.New("missing feedback")
	}

	if uspd.Room == nil {
		return errors.New("missing room data")
	}

	if uspd.Room.Cost < 0 {
		return errors.New("invalid room cost value")
	}

	_, err := Members.GetMember(*uspd.Member)
	if err != nil {
		return errors.New("invalid member ID")
	}

	return nil
}

// UpdateSpeakerParticipation updates a speaker's participation data
// related to the current event.
func (s *SpeakersType) UpdateSpeakerParticipation(speakerID primitive.ObjectID, data UpdateSpeakerParticipationData) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"participations.$.member":   *data.Member,
			"participations.$.feedback": *data.Feedback,
			"participations.$.room": bson.M{
				"type":  data.Room.Type,
				"cost":  data.Room.Cost,
				"notes": data.Room.Notes,
			},
		},
	}

	var filterQuery = bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error updating speaker's status:", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return &updatedSpeaker, nil
}

// StepStatus advances the status of a speaker's participation in the current event,
// according to the given step (see models.Speaker).
func (s *SpeakersType) StepStatus(speakerID primitive.ObjectID, step int) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	speaker, err := s.GetSpeaker(speakerID)
	if err != nil {
		return nil, err
	}

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	for i, p := range speaker.Participations {
		if p.Event != currentEvent.ID {
			continue
		}

		err := speaker.Participations[i].Status.Next(step)

		if err != nil {
			return nil, err
		}

		var updateQuery = bson.M{
			"$set": bson.M{
				"participations.$.status": speaker.Participations[i].Status,
			},
		}

		var filterQuery = bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

		var optionsQuery = options.FindOneAndUpdate()
		optionsQuery.SetReturnDocument(options.After)

		if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
			log.Println("Error updating speaker's status:", err)
			return nil, err
		}

		return &updatedSpeaker, nil
	}

	ResetCurrentPublicSpeakers()

	return nil, errors.New("speaker without participation on the current event")
}

// GetSpeakerParticipationStatusValidSteps gets the valid steps to be taken on speaker's participation status
func (s *SpeakersType) GetSpeakerParticipationStatusValidSteps(speakerID primitive.ObjectID) (*[]models.ValidStep, error) {

	var steps []models.ValidStep

	speaker, err := s.GetSpeaker(speakerID)
	if err != nil {
		return nil, err
	}

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	for i, p := range speaker.Participations {

		if p.Event != currentEvent.ID {
			continue
		}

		steps = speaker.Participations[i].Status.ValidSteps()

		return &steps, nil
	}

	return nil, errors.New("No participation found")
}

// UpdateSpeakerParticipationStatus updates a speaker's participation status
// related to the current event. This is the method used when one does not want necessarily to follow
// the state machine described on models.ParticipationStatus.
func (s *SpeakersType) UpdateSpeakerParticipationStatus(speakerID primitive.ObjectID, status models.ParticipationStatus) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"participations.$.status": status,
		},
	}

	var filterQuery = bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error updating speaker's status:", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return &updatedSpeaker, nil
}

// UpdateSpeakerInternalImage updates the speaker's internal image.
func (s *SpeakersType) UpdateSpeakerInternalImage(speakerID primitive.ObjectID, url string) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	var updateQuery = bson.M{
		"$set": bson.M{
			"imgs.internal": url,
		},
	}

	var filterQuery = bson.M{"_id": speakerID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("error updating speaker:", err)
		return nil, err
	}

	return &updatedSpeaker, nil
}

// UpdateSpeakerCompanyImage updates the speaker's company image.
func (s *SpeakersType) UpdateSpeakerCompanyImage(speakerID primitive.ObjectID, url string) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	var updateQuery = bson.M{
		"$set": bson.M{
			"imgs.company": url,
		},
	}

	var filterQuery = bson.M{"_id": speakerID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("error updating speaker:", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return &updatedSpeaker, nil
}

// UpdateSpeakerPublicImage updates the speaker's public image.
func (s *SpeakersType) UpdateSpeakerPublicImage(speakerID primitive.ObjectID, url string) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	var updateQuery = bson.M{
		"$set": bson.M{
			"imgs.speaker": url,
		},
	}

	var filterQuery = bson.M{"_id": speakerID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("error updating speaker:", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return &updatedSpeaker, nil
}

// DeleteSpeakerThread deletes a thread from a speaker participation
func (s *SpeakersType) DeleteSpeakerThread(id, threadID primitive.ObjectID) (*models.Speaker, error) {
	_, err := s.GetSpeaker(id)
	if err != nil {
		return nil, err
	}

	var updatedSpeaker models.Speaker

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations.$.communications": threadID,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, bson.M{"participations.communications": threadID}, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		return nil, err
	}

	return &updatedSpeaker, nil
}

// AddSpeakerFlightInfo stores a flightInfo on the speaker's participation.
func (s *SpeakersType) AddSpeakerFlightInfo(speakerID primitive.ObjectID, flightInfo primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations.$.flights": flightInfo,
		},
	}

	var filterQuery = bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("error updating speaker's flight info:", err)
		return nil, err
	}

	return &updatedSpeaker, nil
}

// RemoveSpeakerFlightInfo removes a flightInfo on the speaker's participation.
func (s *SpeakersType) RemoveSpeakerFlightInfo(speakerID primitive.ObjectID, flightInfo primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	var updatedSpeaker models.Speaker

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations.$.flights": flightInfo,
		},
	}

	var filterQuery = bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("error updating speaker's flight info:", err)
		return nil, err
	}

	return &updatedSpeaker, nil
}

// AddThread adds a models.Thread to a speaker's participation's list of communications (related to the current event).
func (s *SpeakersType) AddThread(speakerID primitive.ObjectID, threadID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedSpeaker models.Speaker

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations.$.communications": threadID,
		},
	}

	var filterQuery = bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error adding communication to speaker's participation:", err)
		return nil, err
	}

	return &updatedSpeaker, nil
}

// RemoveCommunication removes a models.Thread from a speaker's participation's list of communications (related to the current event).
func (s *SpeakersType) RemoveCommunication(speakerID primitive.ObjectID, threadID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedSpeaker models.Speaker

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations.$.communications": threadID,
		},
	}

	var filterQuery = bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error removing communication to speaker's participation:", err)
		return nil, err
	}

	return &updatedSpeaker, nil
}

//FindThread finds a thread in a speaker
func (s *SpeakersType) FindThread(threadID primitive.ObjectID) (*models.Speaker, error) {
	ctx := context.Background()
	filter := bson.M{
		"participations.communications": threadID,
	}

	cur, err := s.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	var speaker models.Speaker

	if cur.Next(ctx) {
		if err := cur.Decode(&speaker); err != nil {
			return nil, err
		}
		return &speaker, nil
	}

	return nil, nil
}

// RemoveSpeakerParticipation removes a participation from a speaker
func (s *SpeakersType) RemoveSpeakerParticipation(speakerID primitive.ObjectID, eventID int) (*models.Speaker, error) {
	ctx := context.Background()
	var updatedSpeaker models.Speaker

	speaker, err := s.GetSpeaker(speakerID)
	if err != nil {
		return nil, err
	}

	sessions, err := Sessions.GetSessions(GetSessionsOptions{Speaker: &speakerID})
	if err != nil {
		return nil, err
	}

	if len(sessions) > 0 {
		return nil, errors.New("Participation associated with session")
	}

	for _, s := range speaker.Participations {
		if s.Event == eventID {
			if len(s.Communications) > 0 {
				return nil, errors.New("Participation has communication")
			}
      if len(s.Flights) > 0 {
        return nil, errors.New("Participation has flight")
      }
			break
		}
	}

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations": bson.M{
				"event": eventID,
			},
		},
	}

	var filterQuery = bson.M{"_id": speakerID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		return nil, err
	}

	return &updatedSpeaker, nil
}
