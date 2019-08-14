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

type CompaniesType struct {
	Collection *mongo.Collection
	Context    context.Context
}

type CreateCompanyData struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
	Site        *string `json:"site"`
}

// ParseBody fills the CreateCompanyData from a body
func (ccd *CreateCompanyData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ccd); err != nil {
		return err
	}

	if ccd.Name == nil || len(*ccd.Name) == 0 {
		return errors.New("invalid name")
	}

	if ccd.Description == nil {
		return errors.New("invalid description")
	}

	if ccd.Site == nil {
		return errors.New("invalid site")
	}

	return nil
}

// CreateCompany creates a new company and saves it to the database
func (c *CompaniesType) CreateCompany(data CreateCompanyData) (*models.Company, error) {

	insertResult, err := c.Collection.InsertOne(c.Context, bson.M{
		"name":           data.Name,
		"description":    data.Description,
		"site":           data.Site,
		"employers":      []primitive.ObjectID{},
		"participations": []models.CompanyParticipation{},
	})

	if err != nil {
		return nil, err
	}

	newCompany, err := c.GetCompany(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created company", err)
		return nil, err
	}

	return newCompany, nil
}

// GetCompaniesOptions is the options to give to GetCompanies.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetCompaniesOptions struct {
	EventID   *int
	IsPartner *bool
	MemberID  *primitive.ObjectID
	Name      *string
}

// GetCompanies gets all companies specified with a query
func (c *CompaniesType) GetCompanies(options GetCompaniesOptions) ([]*models.Company, error) {
	var companies = make([]*models.Company, 0)

	filter := bson.M{}

	if options.EventID != nil {
		filter["participations.event"] = options.EventID
	}

	if options.IsPartner != nil {
		filter["participations.partner"] = options.IsPartner
	}

	if options.MemberID != nil {
		filter["participations.member"] = options.MemberID
	}

	if options.Name != nil {
		filter["name"] = options.Name
	}

	cur, err := c.Collection.Find(c.Context, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(c.Context) {

		// create a value into which the single document can be decoded
		var c models.Company
		err := cur.Decode(&c)
		if err != nil {
			return nil, err
		}

		companies = append(companies, &c)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(c.Context)

	return companies, nil
}

// GetCompany gets a company by its ID.
func (c *CompaniesType) GetCompany(companyID primitive.ObjectID) (*models.Company, error) {
	var company models.Company

	err := c.Collection.FindOne(c.Context, bson.M{"_id": companyID}).Decode(&company)
	if err != nil {
		return nil, err
	}

	return &company, nil
}

// AddParticipationData is used on AddParticipation. Is the data to be given in order to add a new participation
// to a company, related to the current event.
type AddParticipationData struct {
	Partner bool `json:"partner"`
}

// ParseBody fills the CreateCompanyData from a body
func (apd *AddParticipationData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(apd); err != nil {
		return err
	}

	return nil
}

// AddParticipation adds a participation on the current event to the company with the indicated id.
func (c *CompaniesType) AddParticipation(companyID primitive.ObjectID, memberID primitive.ObjectID, data AddParticipationData) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations": bson.M{
				"event":   currentEvent.ID,
				"member":  memberID,
				"partner": data.Partner,
				"status":  models.Suggested,
			},
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// RemoveParticipation removes a company's participation on the current event.
func (c *CompaniesType) RemoveParticipation(companyID primitive.ObjectID) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations": bson.M{
				"event": currentEvent.ID,
			},
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error removing participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// StepStatus advances the status of a company's participation in the current event,
// according to the given step (see models.Company).
func (c *CompaniesType) StepStatus(companyID primitive.ObjectID, step int) (*models.Company, error) {

	var updatedCompany models.Company

	company, err := c.GetCompany(companyID)
	if err != nil {
		return nil, err
	}

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	for i, p := range company.Participations {
		if p.Event != currentEvent.ID {
			continue
		}

		err := company.Participations[i].Status.Next(step)

		if err != nil {
			return nil, err
		}

		var updateQuery = bson.M{
			"$set": bson.M{
				"participations.$.status": company.Participations[i].Status,
			},
		}

		var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

		var optionsQuery = options.FindOneAndUpdate()
		optionsQuery.SetReturnDocument(options.After)

		if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
			log.Println("Error updating company's status:", err)
			return nil, err
		}

		return &updatedCompany, nil
	}

	return nil, errors.New("company without participation on the current event")
}

// UpdateCompanyParticipationStatus updates a company's participation status
// related to the current event. This is the method used when one does not want necessarily to follow
// the state machine described on models.ParticipationStatus.
func (c *CompaniesType) UpdateCompanyParticipationStatus(companyID primitive.ObjectID, eventID int, status models.ParticipationStatus) (*models.Company, error) {

	var updatedCompany models.Company

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"participations.$.status": status,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error updating company's status:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// UpdateCompanyData is the data used to update a company, using the method UpdateCompany.
type UpdateCompanyData struct {
	Name        string
	Description string
	Site        string
	BillingInfo models.CompanyBillingInfo
}

// UpdateCompany updates the general information about a company, unrelated to other data types stored in de database.
func (c *CompaniesType) UpdateCompany(companyID primitive.ObjectID, data UpdateCompanyData) (*models.Company, error) {

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":                data.Name,
			"description":         data.Description,
			"site":                data.Site,
			"billingInfo.name":    data.BillingInfo.Name,
			"billingInfo.address": data.BillingInfo.Address,
			"billingInfo.tin":     data.BillingInfo.TIN,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("error updating company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// UpdateCompanyInternalImage updates the company's internal image.
func (c *CompaniesType) UpdateCompanyInternalImage(companyID primitive.ObjectID, url string) (*models.Company, error) {

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"imgs.internal": url,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("error updating company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// UpdateCompanyPublicImage updates the company's public image.
func (c *CompaniesType) UpdateCompanyPublicImage(companyID primitive.ObjectID, url string) (*models.Company, error) {

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"imgs.public": url,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("error updating company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// DeleteCompany deletes a company.
func (c *CompaniesType) DeleteCompany(companyID primitive.ObjectID) (*models.Company, error) {

	company, err := Companies.GetCompany(companyID)
	if err != nil {
		return nil, err
	}

	deleteResult, err := Companies.Collection.DeleteOne(Companies.Context, bson.M{"_id": companyID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 company, deleted %v", deleteResult.DeletedCount)
	}

	return company, nil
}

// AddEmployer adds a models.CompanyRep to a company.
func (c *CompaniesType) AddEmployer(companyID primitive.ObjectID, companyRepID primitive.ObjectID) (*models.Company, error) {

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"employers": companyRepID,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// RemoveEmployer removes a models.CompanyRep from a company.
func (c *CompaniesType) RemoveEmployer(companyID primitive.ObjectID, companyRep primitive.ObjectID) (*models.Company, error) {

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$pull": bson.M{
			"employers": companyRep,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// AddThread adds a models.Thread to a company's participation's list of communications (related to the current event).
func (c *CompaniesType) AddThread(companyID primitive.ObjectID, threadID primitive.ObjectID) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations.$.communications": threadID,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error adding communication to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// RemoveCommunication removes a models.Thread from a company's participation's list of communications (related to the current event).
func (c *CompaniesType) RemoveCommunication(companyID primitive.ObjectID, threadID primitive.ObjectID) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations.$.communications": threadID,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error removing communication to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// AddSubscriber adds a models.Member to the list of subscribers of a company's participation in the current event.
func (c *CompaniesType) AddSubscriber(companyID primitive.ObjectID, memberID primitive.ObjectID) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations.$.subscribers": memberID,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error adding subscriber to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// RemoveSubscriber removes a models.Member from the list of subscribers of a company's participation in the current event.
func (c *CompaniesType) RemoveSubscriber(companyID primitive.ObjectID, memberID primitive.ObjectID) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations.$.subscribers": memberID,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error removing subscriber to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// UpdateBilling updates the billing information on a company's participation related to the current event.
// Uses a models.Billing ID to store this information.
func (c *CompaniesType) UpdateBilling(companyID primitive.ObjectID, billingID primitive.ObjectID) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"participations.$.billing": billingID,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error updating company's participation's billing:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// UpdatePackage updates the package of a company's participation related to the current event.
// Uses a models.Package ID to store this information.
func (c *CompaniesType) UpdatePackage(companyID primitive.ObjectID, packageID primitive.ObjectID) (*models.Company, error) {

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"participations.$.package": packageID,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(c.Context, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error updating company's participation's package:", err)
		return nil, err
	}

	return &updatedCompany, nil
}
