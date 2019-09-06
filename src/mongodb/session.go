package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

type SessionsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// Cached version of the public sessions for the current event
var currentPublicSessions *[]*models.SessionPublic

func ResetCurrentPublicSessions() {
	currentPublicSessions = nil
}

func sessionToPublic(session models.Session, eventID int) (*models.SessionPublic, error) {

	public := models.SessionPublic{
		Begin:             session.Begin,
		End:               session.End,
		Title:             session.Title,
		Description:       session.Description,
		Space:             session.Space,
		Kind:              session.Kind,
		SessionDinamizers: session.SessionDinamizers,
		VideoURL:          session.VideoURL,
	}

	if session.Company != nil {
		if company, err := Companies.GetCompany(*session.Company); err == nil {
			if publicCompany, err := companyToPublic(*company, eventID); err == nil {
				public.CompanyPublic = publicCompany
			}
		}
	}

	if session.Speaker != nil {
		if speaker, err := Speakers.GetSpeaker(*session.Speaker); err == nil {
			if publicSpeaker, err := speakerToPublic(*speaker, eventID); err == nil {
				public.SpeakerPublic = publicSpeaker
			}
		}
	}

	if session.Tickets != nil {
		public.Tickets = session.Tickets
	}

	return &public, nil
}

// CreateSessionData is the structure used on CreateSession
type CreateSessionData struct {
	Begin             *time.Time                  `json:"begin"`
	End               *time.Time                  `json:"end"`
	Title             *string                     `json:"title"`
	Description       *string                     `json:"description"`
	Space             *string                     `json:"space"`
	Kind              *string                     `json:"kind"`
	Company           *primitive.ObjectID         `json:"company"`
	SessionDinamizers *[]models.SessionDinamizers `json:"dinamizers" bson:"dinamizers"`
	Speaker           *primitive.ObjectID         `json:"speaker"`
	Tickets           *models.SessionTickets      `json:"tickets"`
}

// ParseBody fills the CreateSessionData from a body
func (csd *CreateSessionData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(csd); err != nil {
		return err
	}

	var now = time.Now()

	if csd.Begin == nil {
		return errors.New("invalid begin date")
	}

	if csd.End == nil {
		return errors.New("invalid end date")
	}

	if now.After(*csd.Begin) || now.After(*csd.End) {
		return errors.New("invalid begin or end dates: must be in the future")
	}

	if csd.Begin.After(*csd.End) {
		return errors.New("invalid begin or end dates: end must be after begin")
	}

	if csd.Title == nil || len(*csd.Title) == 0 {
		return errors.New("invalid title")
	}

	if csd.Description == nil || len(*csd.Description) == 0 {
		return errors.New("invalid description")
	}

	if csd.Kind == nil {
		return errors.New("invalid kind")
	}

	var sk = new(models.SessionKind)
	if err := sk.Parse(*csd.Kind); err != nil {
		return errors.New("invalid kind")
	}

	if *sk == models.SessionKindTalk && csd.Speaker == nil {
		return errors.New("invalid speaker")
	}

	if *sk == models.SessionKindTalk {

		if csd.Speaker == nil {
			return errors.New("invalid speaker")
		}

		if _, err := Speakers.GetSpeaker(*csd.Speaker); err != nil {
			return errors.New("speaker not found")
		}

	}

	if *sk == models.SessionKindWorkshop || *sk == models.SessionKindPresentation {

		if csd.Company == nil {
			return errors.New("invalid company")
		}

		if _, err := Companies.GetCompany(*csd.Company); err != nil {
			return errors.New("company not found")
		}

	}

	if csd.Tickets != nil {
		if csd.Tickets.Start.After(csd.Tickets.End) {
			return errors.New("tickets: start must be before end")
		}

		if csd.Tickets.Start.Before(now) || csd.Tickets.End.Before(now) {
			return errors.New("tickets: start and end must be in the future")
		}

		if csd.Tickets.Max <= 0 {
			return errors.New("maximum number of tickets must be a positive integer")
		}
	}

	return nil
}

// CreateSession creates a new session.
func (s *SessionsType) CreateSession(data CreateSessionData) (*models.Session, error) {

	var session models.Session

	var c = bson.M{
		"begin":       data.Begin.UTC(),
		"end":         data.End.UTC(),
		"title":       data.Title,
		"description": data.Description,
		"kind":        data.Kind,
	}

	if data.Space != nil {
		c["space"] = data.Space
	}

	if data.Company != nil {
		c["company"] = data.Company
	}

	if data.SessionDinamizers != nil {
		c["dinamizers"] = data.SessionDinamizers
	} else {
		c["dinamizers"] = make([]models.SessionDinamizers, 0)
	}

	if data.Speaker != nil {
		c["speaker"] = data.Speaker
	}

	if data.Tickets != nil {
		c["tickets"] = bson.M{
			"start": data.Tickets.Start.UTC(),
			"end":   data.Tickets.End.UTC(),
			"max":   data.Tickets.Max,
		}
	}

	insertResult, err := s.Collection.InsertOne(s.Context, c)

	if err != nil {
		log.Fatal(err)
	}

	if err := s.Collection.FindOne(s.Context, bson.M{"_id": insertResult.InsertedID}).Decode(&session); err != nil {
		log.Println("Error finding created session:", err)
		return nil, err
	}

	ResetCurrentPublicSessions()

	return &session, nil
}

// GetSession gets an session by its ID
func (s *SessionsType) GetSession(sessionID primitive.ObjectID) (*models.Session, error) {
	var session models.Session

	err := s.Collection.FindOne(s.Context, bson.M{"_id": sessionID}).Decode(&session)
	if err != nil {
		return nil, err
	}

	return &session, nil
}

// UpdateSessionData is the structure used in UpdateItem
type UpdateSessionData struct {
	Begin             *time.Time                  `json:"begin"`
	End               *time.Time                  `json:"end"`
	Title             *string                     `json:"title"`
	Description       *string                     `json:"description"`
	Space             *string                     `json:"space"`
	Kind              *string                     `json:"kind"`
	Company           *primitive.ObjectID         `json:"company"`
	SessionDinamizers *[]models.SessionDinamizers `json:"dinamizers" bson:"dinamizers"`
	Speaker           *primitive.ObjectID         `json:"speaker"`
	VideoURL          *string                     `json:"videoURL"`
	Tickets           *models.SessionTickets      `json:"tickets"`
}

// ParseBody fills the CreateItemData from a body
func (usd *UpdateSessionData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(usd); err != nil {
		return err
	}

	if usd.Begin == nil {
		return errors.New("invalid begin date")
	}

	if usd.End == nil {
		return errors.New("invalid end date")
	}

	if usd.Begin.After(*usd.End) {
		return errors.New("invalid begin or end dates: end must be after begin")
	}

	if usd.Title == nil || len(*usd.Title) == 0 {
		return errors.New("invalid title")
	}

	if usd.Description == nil || len(*usd.Description) == 0 {
		return errors.New("invalid description")
	}

	if usd.Kind == nil {
		return errors.New("invalid kind")
	}

	var sk = new(models.SessionKind)
	if err := sk.Parse(*usd.Kind); err != nil {
		return errors.New("invalid kind")
	}

	if *sk == models.SessionKindTalk && usd.Speaker == nil {
		return errors.New("invalid speaker")
	}

	if *sk == models.SessionKindWorkshop && usd.Company == nil {
		return errors.New("invalid company")
	}

	if *sk == models.SessionKindPresentation && usd.Company == nil {
		return errors.New("invalid company")
	}

	var now = time.Now()

	if usd.Tickets != nil {
		if usd.Tickets.Start.After(usd.Tickets.End) {
			return errors.New("tickets: start must be before end")
		}

		if usd.Tickets.Start.Before(now) || usd.Tickets.End.Before(now) {
			return errors.New("tickets: start and end must be in the future")
		}

		if usd.Tickets.Max <= 0 {
			return errors.New("maximum number of tickets must be a positive integer")
		}
	}

	return nil
}

// UpdateSession updates a session by its ID
func (s *SessionsType) UpdateSession(sessionID primitive.ObjectID, data UpdateSessionData) (*models.Session, error) {

	var session models.Session

	var c = bson.M{
		"begin":       data.Begin.UTC(),
		"end":         data.End.UTC(),
		"title":       data.Title,
		"description": data.Description,
		"kind":        data.Kind,
	}

	if data.Space != nil {
		c["space"] = data.Space
	}

	if data.Company != nil {
		c["company"] = data.Company
	}

	if data.SessionDinamizers != nil {
		c["dinamizers"] = data.SessionDinamizers
	} else {
		c["dinamizers"] = make([]models.SessionDinamizers, 0)
	}

	if data.Speaker != nil {
		c["speaker"] = data.Speaker
	}

	if data.VideoURL != nil {
		c["videoURL"] = data.VideoURL
	}

	if data.Tickets != nil {
		c["tickets"] = bson.M{
			"start": data.Tickets.Start.UTC(),
			"end":   data.Tickets.End.UTC(),
			"max":   data.Tickets.Max,
		}
	}

	var updateQuery = bson.M{"$set": c}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(s.Context, bson.M{"_id": sessionID}, updateQuery, optionsQuery).Decode(&session); err != nil {
		return nil, err
	}

	ResetCurrentPublicSessions()

	return &session, nil
}

// DeleteSession deletes a session by its ID.
func (s *SessionsType) DeleteSession(sessionID primitive.ObjectID) (*models.Session, error) {

	var session models.Session

	err := s.Collection.FindOneAndDelete(s.Context, bson.M{"_id": sessionID}).Decode(&session)
	if err != nil {
		return nil, err
	}

	return &session, nil
}

// GetSessionsOptions is a filter for GetSessions
type GetSessionsOptions struct {
	Event   *int
	Before  *time.Time
	After   *time.Time
	Space   *string
	Kind    *models.SessionKind
	Company *primitive.ObjectID
	Speaker *primitive.ObjectID
}

// GetSessions retrieves all sessions from the current event if no event is specified
func (s *SessionsType) GetSessions(options GetSessionsOptions) ([]*models.Session, error) {

	var sessions = make([]*models.Session, 0)

	var event *models.Event
	var err error

	if options.Event == nil {

		// if no event given, then just use the current event
		event, err = Events.GetCurrentEvent()
		if err != nil {
			return nil, err
		}

	} else {

		event, err = Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}

	}

	var keep bool
	for _, sessionID := range event.Sessions {

		session, err := Sessions.GetSession(sessionID)
		if err != nil {
			continue
		}

		keep = true

		if options.Before != nil {
			keep = session.Begin.Before(*options.Before)
		}

		if options.After != nil {
			keep = session.End.After(*options.After)
		}

		if options.Space != nil {
			keep = session.Space == *options.Space
		}

		if options.Kind != nil {
			keep = session.Kind == *options.Kind
		}

		if options.Company != nil {
			keep = *session.Company == *options.Company
		}

		if options.Speaker != nil {
			keep = *session.Speaker == *options.Speaker
		}

		if keep {
			sessions = append(sessions, session)
		}

	}

	return sessions, nil
}

// GetSessionsPublicOptions is the options to give to GetSessionsPublic.
type GetSessionsPublicOptions struct {
	EventID *int
	Kind    *models.SessionKind
}

// GetPublicSessions gets all sessions specified with a query to be shown publicly
func (s *SessionsType) GetPublicSessions(options GetSessionsPublicOptions) ([]*models.SessionPublic, error) {

	var public = make([]*models.SessionPublic, 0)
	var filtered = make([]*models.Session, 0)
	var sessions []*models.Session
	var err error

	if currentPublicCompanies != nil {

		var filtered = make([]*models.SessionPublic, 0)

		if options.Kind != nil {

			for _, s := range *currentPublicSessions {
				if s.Kind == *options.Kind {
					filtered = append(filtered, s)
				}
			}

		} else {
			filtered = *currentPublicSessions
		}

		// return cached value
		return filtered, nil

	}

	sessions, err = Sessions.GetSessions(GetSessionsOptions{Event: options.EventID})
	if err != nil {
		return nil, err
	}

	if options.Kind != nil {

		for _, s := range sessions {
			if s.Kind == *options.Kind {
				filtered = append(filtered, s)
			}
		}

	} else {
		filtered = sessions
	}

	var event *models.Event
	if options.EventID == nil {
		event, err = Events.GetCurrentEvent()
		if err != nil {
			return nil, err
		}
	} else {
		event, err = Events.GetEvent(*options.EventID)
		if err != nil {
			return nil, err
		}
	}

	for _, session := range filtered {
		p, err := sessionToPublic(*session, event.ID)
		if err != nil {
			return nil, err
		}
		public = append(public, p)
	}

	if options.EventID == nil && options.Kind == nil && currentPublicSessions == nil {
		currentPublicSessions = &public
	}

	return public, nil
}
