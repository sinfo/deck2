package mongodb

import (
	"context"
	"encoding/json"
	"io"
	"log"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ============================================================
// Company Tasks
// ============================================================

// UpdateCompanyTasksData holds the payload sent by the frontend.
type UpdateCompanyTasksData struct {
	Tasks *models.CompanyTasks `json:"tasks"`
}

// ParseBody fills the UpdateCompanyTasksData from a request body.
func (d *UpdateCompanyTasksData) ParseBody(body io.Reader) error {
	if err := json.NewDecoder(body).Decode(d); err != nil {
		return err
	}
	return nil
}

// UpdateCompanyTasks persists the task data on the company's current-event participation.
func (c *CompaniesType) UpdateCompanyTasks(companyID primitive.ObjectID, data UpdateCompanyTasksData) (*models.Company, error) {
	ctx := context.Background()
	var updatedCompany models.Company

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	setFields := bson.M{
		"participations.$.tasks": data.Tasks,
	}

	updateQuery := bson.M{"$set": setFields}
	filterQuery := bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	optionsQuery := options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error updating company tasks:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// ============================================================
// Speaker Tasks
// ============================================================

// UpdateSpeakerTasksData holds the payload sent by the frontend.
type UpdateSpeakerTasksData struct {
	Tasks *models.SpeakerTasks `json:"tasks"`
}

// ParseBody fills the UpdateSpeakerTasksData from a request body.
func (d *UpdateSpeakerTasksData) ParseBody(body io.Reader) error {
	if err := json.NewDecoder(body).Decode(d); err != nil {
		return err
	}
	return nil
}

// UpdateSpeakerTasks persists the task data on the speaker's current-event participation.
func (s *SpeakersType) UpdateSpeakerTasks(speakerID primitive.ObjectID, data UpdateSpeakerTasksData) (*models.Speaker, error) {
	ctx := context.Background()
	var updatedSpeaker models.Speaker

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	setFields := bson.M{
		"participations.$.tasks": data.Tasks,
	}

	updateQuery := bson.M{"$set": setFields}
	filterQuery := bson.M{"_id": speakerID, "participations.event": currentEvent.ID}

	optionsQuery := options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := s.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedSpeaker); err != nil {
		log.Println("Error updating speaker tasks:", err)
		return nil, err
	}

	ResetCurrentPublicSpeakers()

	return &updatedSpeaker, nil
}
