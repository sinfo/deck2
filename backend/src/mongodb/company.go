package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// CompaniesType holds collection info
type CompaniesType struct {
	Collection *mongo.Collection
}

// Cached version of the public companies for the current event
var currentPublicCompanies *[]*models.CompanyPublic

//ResetCurrentPublicCompanies resets current public companies
func ResetCurrentPublicCompanies() {
	currentPublicCompanies = nil
}

// CreateCompanyData holds data needed to create a company
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

	ctx := context.Background()

	insertResult, err := c.Collection.InsertOne(ctx, bson.M{
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

	ResetCurrentPublicCompanies()

	return newCompany, nil
}

// GetCompaniesOptions is the options to give to GetCompanies.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetCompaniesOptions struct {
	EventID          *int
	IsPartner        *bool
	MemberID         *primitive.ObjectID
	Name             *string
	NumRequests      *int64
	MaxCompInRequest *int64
	SortingMethod    *string
}

const (
	NumberParticipations string = "NUM_PARTICIPATIONS"
	LastParticipation    string = "LAST_PARTICIPATION"
)

// GetCompanies gets all companies specified with a query
func (c *CompaniesType) GetCompanies(compOptions GetCompaniesOptions) ([]*models.Company, error) {
	var companies = make([]*models.Company, 0)

	ctx := context.Background()

	filter := bson.M{}
	elemMatch := bson.M{}

	findOptions := options.Find()

	if compOptions.EventID != nil {
		elemMatch["event"] = compOptions.EventID
	}

	if compOptions.IsPartner != nil {
		elemMatch["partner"] = compOptions.IsPartner
	}

	if compOptions.MemberID != nil {
		elemMatch["member"] = compOptions.MemberID
	}

	filter["participations"] = bson.M{
		"$elemMatch": elemMatch,
	}

	if compOptions.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *compOptions.Name),
			"$options": "i",
		}
	}

	if compOptions.MaxCompInRequest != nil && compOptions.SortingMethod == nil {
		findOptions.SetLimit(*compOptions.MaxCompInRequest)
	}

	if compOptions.NumRequests != nil && compOptions.SortingMethod == nil {
		findOptions.SetSkip(*compOptions.NumRequests * (*compOptions.MaxCompInRequest))
	}

	var err error
	var cur *mongo.Cursor
	if compOptions.SortingMethod != nil {
		switch *compOptions.SortingMethod {
		case string(NumberParticipations):
			query := mongo.Pipeline{
				{
					{Key: "$match", Value: filter},
				},
				{
					{Key: "$addFields", Value: bson.D{
						{Key: "numParticipations", Value: bson.D{
							{Key: "$size", Value: "$participations"},
						}},
					}},
				},
				{
					{Key: "$sort", Value: bson.D{
						{Key: "numParticipations", Value: -1},
					}},
				},
				{
					{Key: "$skip", Value: (*compOptions.NumRequests * (*compOptions.MaxCompInRequest))},
				},
				{
					{Key: "$limit", Value: *compOptions.MaxCompInRequest},
				},
			}
			cur, err = c.Collection.Aggregate(ctx, query)
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
					{Key: "$sort", Value: bson.D{
						{Key: "participations.event", Value: -1},
					}},
				},
				{
					{Key: "$skip", Value: (*compOptions.NumRequests * (*compOptions.MaxCompInRequest))},
				},
				{
					{Key: "$limit", Value: *compOptions.MaxCompInRequest},
				},
			}
			cur, err = c.Collection.Aggregate(ctx, query)
			if err != nil {
				return nil, err
			}
			break
		default:
			return nil, errors.New("error parsing Sorting Method")
		}
	} else {
		cur, err = c.Collection.Find(ctx, filter, findOptions)
		if err != nil {
			return nil, err
		}
	}

	for cur.Next(ctx) {

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

	cur.Close(ctx)

	return companies, nil
}

// Transforms a models.Company into a models.CompanyPublic. If eventID != nil, returns only the participation for that event, if announced.
// Otherwise, returns all participations in which they were announced
func companyToPublic(company models.Company, eventID *int) (*models.CompanyPublic, error) {

	public := models.CompanyPublic{
		ID:          company.ID,
		Name:        company.Name,
		Image:       company.Images.Public,
		Site:        company.Site,
		Description: company.Description,
	}

	var participation *models.CompanyParticipation

	for _, p := range company.Participations {
		if eventID == nil && p.Status == models.Announced {
			participation = &p
		} else if eventID != nil {
			if p.Event == *eventID {

				if p.Status != models.Announced {
					return nil, fmt.Errorf("company not announced on event %d", eventID)
				}

				participation = &p
			}
		}

		if participation != nil {
			var participationObj models.CompanyParticipationPublic

			participationObj = models.CompanyParticipationPublic{
				Event:   p.Event,
				Partner: participation.Partner,
				Package: models.PackagePublic{},
			}

			pack, err := Packages.GetPackage(participation.Package)
			if err == nil {
				participationObj.Package = models.PackagePublic{
					Name:  pack.Name,
					Items: make([]models.PackageItemPublic, 0),
				}

				// add only public items
				for _, item := range pack.Items {
					if item.Public {
						participationObj.Package.Items = append(
							participationObj.Package.Items,
							models.PackageItemPublic{
								Item:     item.Item,
								Quantity: item.Quantity,
							})
					}
				}
			}

			public.Participations = append(public.Participations, participationObj)
		}
	}

	return &public, nil
}

// GetCompaniesPublicOptions is the options to give to GetCompanies.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetCompaniesPublicOptions struct {
	EventID   *int
	IsPartner *bool
	Name      *string
}

// GetPublicCompanies gets all companies specified with a query to be shown publicly
func (c *CompaniesType) GetPublicCompanies(options GetCompaniesPublicOptions) ([]*models.CompanyPublic, error) {

	ctx := context.Background()

	var public = make([]*models.CompanyPublic, 0)
	var eventID int

	filter := bson.M{}

	if options.EventID == nil && options.IsPartner == nil &&
		options.Name == nil && currentPublicCompanies != nil {

		// return cached value
		return *currentPublicCompanies, nil
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

	if options.IsPartner != nil {
		filter["participations.partner"] = options.IsPartner
	}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	cur, err := c.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {

		// create a value into which the single document can be decoded
		var c models.Company
		err := cur.Decode(&c)
		if err != nil {
			return nil, err
		}

		p, err := companyToPublic(c, &eventID)
		if err == nil {
			public = append(public, p)
		}

	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(ctx)

	// update cached value
	if options.EventID == nil && options.IsPartner == nil &&
		options.Name == nil && currentPublicCompanies == nil {

		currentPublicCompanies = &public
	}

	return public, nil
}

// GetCompany gets a company by its ID.
func (c *CompaniesType) GetCompany(companyID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
	var company models.Company

	err := c.Collection.FindOne(ctx, bson.M{"_id": companyID}).Decode(&company)
	if err != nil {
		return nil, err
	}

	return &company, nil
}

// Subscribe a user to the current speaker's participation
func (c *CompaniesType) Subscribe(companyID primitive.ObjectID, memberID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()

	var updatedCompany models.Company

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var filterQuery = bson.M{
		"_id":                  companyID,
		"participations.event": currentEvent.ID,
	}

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations.$.subscribers": memberID,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding updated company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// GetCompanyPublic gets a public company by id
func (c *CompaniesType) GetCompanyPublic(id primitive.ObjectID) (*models.CompanyPublic, error) {
	var company models.Company

	err := c.Collection.FindOne(ctx, bson.M{"_id": id}).Decode(&company)
	if err != nil {
		return nil, err
	}

	public, err := companyToPublic(company, nil)
	if err != nil {
		return nil, err
	}

	return public, nil
}

// Unsubscribe a user to the current speaker's participation
func (c *CompaniesType) Unsubscribe(companyID primitive.ObjectID, memberID primitive.ObjectID) (*models.Company, error) {

	var updatedCompany models.Company

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var filterQuery = bson.M{
		"_id":                  companyID,
		"participations.event": currentEvent.ID,
	}

	var updateQuery = bson.M{
		"$pull": bson.M{
			"participations.$.subscribers": memberID,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding updated company:", err)
		return nil, err
	}

	return &updatedCompany, nil
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

	ctx := context.Background()

	currentEvent, err := Events.GetCurrentEvent()

	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"participations": bson.M{
				"event":          currentEvent.ID,
				"member":         memberID,
				"partner":        data.Partner,
				"status":         models.Suggested,
				"communications": []primitive.ObjectID{},
				"subscribers":    []primitive.ObjectID{memberID},
			},
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": bson.M{"$ne": currentEvent.ID}}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding created company:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// RemoveParticipation removes a company's participation on the current event.
func (c *CompaniesType) RemoveParticipation(companyID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error removing participation:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// StepStatus advances the status of a company's participation in the current event,
// according to the given step (see models.Company).
func (c *CompaniesType) StepStatus(companyID primitive.ObjectID, step int) (*models.Company, error) {

	ctx := context.Background()
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

		if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
			log.Println("Error updating company's status:", err)
			return nil, err
		}

		ResetCurrentPublicCompanies()

		return &updatedCompany, nil
	}

	return nil, errors.New("company without participation on the current event")
}

// GetCompanyParticipationStatusValidSteps gets the valid steps to be taken on company's participation status
func (c *CompaniesType) GetCompanyParticipationStatusValidSteps(companyID primitive.ObjectID) (*[]models.ValidStep, error) {

	var steps []models.ValidStep

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

		steps = company.Participations[i].Status.ValidSteps()

		return &steps, nil
	}

	return nil, errors.New("No participation found")
}

// UpdateCompanyParticipationData holds data needed to update a company's participation
type UpdateCompanyParticipationData struct {
	Member    *primitive.ObjectID `json:"member"`
	Partner   *bool               `json:"partner"`
	Confirmed *time.Time          `json:"confirmed"`
	Notes     *string             `json:"notes"`
}

// ParseBody fills the UpdateCompanyParticipationData from a body
func (ucpd *UpdateCompanyParticipationData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ucpd); err != nil {
		return err
	}

	if ucpd.Member == nil {
		return errors.New("invalid member ID")
	}

	if ucpd.Partner == nil {
		return errors.New("invalid partner value")
	}

	if ucpd.Confirmed == nil {
		return errors.New("invalid confirmation date")
	}

	if ucpd.Notes == nil {
		return errors.New("missing notes field")
	}

	_, err := Members.GetMember(*ucpd.Member)
	if err != nil {
		return errors.New("invalid member ID")
	}

	return nil
}

// UpdateCompanyParticipation updates a company's participation data
// related to the current event.
func (c *CompaniesType) UpdateCompanyParticipation(companyID primitive.ObjectID, data UpdateCompanyParticipationData) (*models.Company, error) {

	ctx := context.Background()
	var updatedCompany models.Company

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"participations.$.member":    *data.Member,
			"participations.$.partner":   *data.Partner,
			"participations.$.confirmed": data.Confirmed.UTC(),
			"participations.$.notes":     *data.Notes,
		},
	}

	var filterQuery = bson.M{"_id": companyID, "participations.event": currentEvent.ID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error updating company's status:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// UpdateCompanyParticipationStatus updates a company's participation status
// related to the current event. This is the method used when one does not want necessarily to follow
// the state machine described on models.ParticipationStatus.
func (c *CompaniesType) UpdateCompanyParticipationStatus(companyID primitive.ObjectID, status models.ParticipationStatus) (*models.Company, error) {

	ctx := context.Background()
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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error updating company's status:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// UpdateCompanyData is the data used to update a company, using the method UpdateCompany.
type UpdateCompanyData struct {
	Name        string
	Description string
	Site        string
	BillingInfo models.CompanyBillingInfo
}

// ParseBody fills the UpdateCompanyData from a body
func (ucd *UpdateCompanyData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(ucd); err != nil {
		return err
	}

	if len(ucd.Name) == 0 {
		return errors.New("Invalid name")
	}

	return nil
}

// UpdateCompany updates the general information about a company, unrelated to other data types stored in de database.
func (c *CompaniesType) UpdateCompany(companyID primitive.ObjectID, data UpdateCompanyData) (*models.Company, error) {

	ctx := context.Background()
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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("error updating company:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// UpdateCompanyInternalImage updates the company's internal image.
func (c *CompaniesType) UpdateCompanyInternalImage(companyID primitive.ObjectID, url string) (*models.Company, error) {

	ctx := context.Background()
	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"imgs.internal": url,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("error updating company:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// UpdateCompanyPublicImage updates the company's public image.
func (c *CompaniesType) UpdateCompanyPublicImage(companyID primitive.ObjectID, url string) (*models.Company, error) {

	ctx := context.Background()
	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$set": bson.M{
			"imgs.public": url,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("error updating company:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// DeleteCompany deletes a company.
func (c *CompaniesType) DeleteCompany(companyID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
	company, err := Companies.GetCompany(companyID)
	if err != nil {
		return nil, err
	}

	deleteResult, err := Companies.Collection.DeleteOne(ctx, bson.M{"_id": companyID})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 company, deleted %v", deleteResult.DeletedCount)
	}

	ResetCurrentPublicCompanies()

	return company, nil
}

// AddEmployer adds a models.CompanyRep to a company.
func (c *CompaniesType) AddEmployer(companyID primitive.ObjectID, data CreateCompanyRepData) (*models.Company, error) {

	ctx := context.Background()
	rep, err := CompanyReps.CreateCompanyRep(data)
	if err != nil {
		return nil, err
	}

	var updatedCompany models.Company

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"employers": rep.ID,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// RemoveEmployer removes a models.CompanyRep from a company.
func (c *CompaniesType) RemoveEmployer(companyID primitive.ObjectID, companyRep primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
	var updatedCompany models.Company

	if _, err := CompanyReps.DeleteCompanyRep(companyRep); err != nil {
		return nil, err
	}

	var updateQuery = bson.M{
		"$pull": bson.M{
			"employers": companyRep,
		},
	}

	var filterQuery = bson.M{"_id": companyID}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error finding created company:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// AddThread adds a models.Thread to a company's participation's list of communications (related to the current event).
func (c *CompaniesType) AddThread(companyID primitive.ObjectID, threadID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error adding communication to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// RemoveCommunication removes a models.Thread from a company's participation's list of communications (related to the current event).
func (c *CompaniesType) RemoveCommunication(companyID primitive.ObjectID, threadID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error removing communication to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// AddSubscriber adds a models.Member to the list of subscribers of a company's participation in the current event.
func (c *CompaniesType) AddSubscriber(companyID primitive.ObjectID, memberID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()

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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error adding subscriber to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// RemoveSubscriber removes a models.Member from the list of subscribers of a company's participation in the current event.
func (c *CompaniesType) RemoveSubscriber(companyID primitive.ObjectID, memberID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error removing subscriber to company's participation:", err)
		return nil, err
	}

	return &updatedCompany, nil
}

// UpdatePackage updates the package of a company's participation related to the current event.
// Uses a models.Package ID to store this information.
func (c *CompaniesType) UpdatePackage(companyID primitive.ObjectID, packageID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
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

	if err := c.Collection.FindOneAndUpdate(ctx, filterQuery, updateQuery, optionsQuery).Decode(&updatedCompany); err != nil {
		log.Println("Error updating company's participation's package:", err)
		return nil, err
	}

	ResetCurrentPublicCompanies()

	return &updatedCompany, nil
}

// FindThread finds a thread in a company
func (c *CompaniesType) FindThread(threadID primitive.ObjectID) (*models.Company, error) {

	ctx := context.Background()
	filter := bson.M{
		"participations.communications": threadID,
	}

	cur, err := c.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	var company models.Company

	if cur.Next(ctx) {
		if err := cur.Decode(&company); err != nil {
			return nil, err
		}
		return &company, nil
	}

	return nil, nil
}
