package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"strings"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson"
)

// ContactsType stores importat db information on contacts
type ContactsType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// GetContactsOptions is used as a filter on GetContacts
type GetContactsOptions struct {
	Phone *string `json:"phone"`
	Mail  *string `json:"mail"`
}

// CreateContactData contains data needed to create a contact
type CreateContactData struct {
	Phones  []models.ContactPhone `json:"phones" bson:"phones"`
	Socials models.ContactSocials `json:"socials" bson:"socials"`
	Mails   []models.ContactMail  `json:"mails" bson:"mails"`
}

// UpdatePhonesData contains data needed to update a contact's phone list
type UpdatePhonesData struct {
	Phones []models.ContactPhone `json:"phones"`
}

// UpdateMailsData contains data needed to update a contact's mail list
type UpdateMailsData struct {
	Mails []models.ContactMail `json:"mails"`
}

// ParseBody fills a CreateContactData struct from a body
func (ccd *CreateContactData) ParseBody(body io.Reader) error {
	if err := json.NewDecoder(body).Decode(ccd); err != nil {
		return err
	}

	for _, s := range ccd.Phones {
		if len(s.Phone) == 0 {
			return errors.New("Invalid phone number")
		}
	}
	for _, s := range ccd.Mails {
		if len(s.Mail) == 0 {
			return errors.New("Invalid mail")
		}
	}

	return nil
}

func partialMatch(s1, s2 string) bool {
	return strings.Contains(strings.ToLower(s1), strings.ToLower(s2))
}

// GetContact finds a contact based on ID
func (c *ContactsType) GetContact(id primitive.ObjectID) (*models.Contact, error) {

	var contact models.Contact

	if err := c.Collection.FindOne(c.Context, bson.M{"_id": id}).Decode(&contact); err != nil {
		return nil, err
	}

	return &contact, nil

}

// GetContacts gets all contacts based on a query
func (c *ContactsType) GetContacts(options GetContactsOptions) ([]*models.Contact, error) {
	var contacts = make([]*models.Contact, 0)

	curr, err := c.Collection.Find(c.Context, bson.M{})
	if err != nil {
		return nil, err
	}

	for curr.Next(c.Context) {
		var contact models.Contact

		if err := curr.Decode(&contact); err != nil {
			return nil, err
		}

		if options.Mail == nil {
			if options.Phone == nil {
				contacts = append(contacts, &contact)
			} else if contact.HasPhone(*options.Phone) {
				contacts = append(contacts, &contact)
			}
		} else if contact.HasMail(*options.Mail) {
			if options.Phone == nil {
				contacts = append(contacts, &contact)
			} else if contact.HasPhone(*options.Phone) {
				contacts = append(contacts, &contact)
			}
		}
	}

	curr.Close(c.Context)

	return contacts, nil
}

// CreateContact addas a contact
func (c *ContactsType) CreateContact(data CreateContactData) (*models.Contact, error) {
	var insertData = bson.M{}
	insertData["phones"] = data.Phones
	insertData["socials"] = data.Socials
	insertData["mails"] = data.Mails

	insertResult, err := c.Collection.InsertOne(c.Context, insertData)
	if err != nil {
		return nil, err
	}

	newContact, err := c.GetContact(insertResult.InsertedID.(primitive.ObjectID))
	if err != nil {
		return nil, err
	}

	return newContact, nil
}

// UpdateContact updates a contact
func (c *ContactsType) UpdateContact(contactID primitive.ObjectID, data CreateContactData) (*models.Contact, error) {
	var updateQuery = bson.M{
		"$set": bson.M{
			"phones":  data.Phones,
			"socials": data.Socials,
			"mails":   data.Mails,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var contact models.Contact

	if err := c.Collection.FindOneAndUpdate(c.Context, bson.M{"_id": contactID}, updateQuery, optionsQuery).Decode(&contact); err != nil {
		return nil, err
	}

	return &contact, nil
}

// AddPhone adds a new phone number to a contact
func (c *ContactsType) AddPhone(id primitive.ObjectID, data models.ContactPhone) (*models.Contact, error) {
	var contact *models.Contact

	contact, err := c.GetContact(id)
	if err != nil {
		return nil, err
	}

	phones := append(contact.Phones, data)

	var updateQuery = bson.M{
		"$set": bson.M{
			"phones": phones,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedContact models.Contact

	if err := c.Collection.FindOneAndUpdate(c.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&updatedContact); err != nil {
		return nil, err
	}

	return &updatedContact, nil
}

// AddMail adds a new phone number to a contact
func (c *ContactsType) AddMail(id primitive.ObjectID, data models.ContactMail) (*models.Contact, error) {
	var contact *models.Contact

	contact, err := c.GetContact(id)
	if err != nil {
		return nil, err
	}

	mails := append(contact.Mails, data)

	var updateQuery = bson.M{
		"$set": bson.M{
			"mails": mails,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedContact models.Contact

	if err := c.Collection.FindOneAndUpdate(c.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&updatedContact); err != nil {
		return nil, err
	}

	return &updatedContact, nil
}

// UpdatePhoneNumbers updates a contact's phone list
func (c *ContactsType) UpdatePhoneNumbers(id primitive.ObjectID, data UpdatePhonesData) (*models.Contact, error) {

	var updateQuery = bson.M{
		"$set": bson.M{
			"phones": data.Phones,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedContact models.Contact

	if err := c.Collection.FindOneAndUpdate(c.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&updatedContact); err != nil {
		return nil, err
	}

	return &updatedContact, nil
}

// UpdateMailList updates a contact's phone list
func (c *ContactsType) UpdateMailList(id primitive.ObjectID, data UpdateMailsData) (*models.Contact, error) {

	var updateQuery = bson.M{
		"$set": bson.M{
			"mails": data.Mails,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedContact models.Contact

	if err := c.Collection.FindOneAndUpdate(c.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&updatedContact); err != nil {
		return nil, err
	}

	return &updatedContact, nil
}

// UpdateSocials updates the socials of a contact
func (c *ContactsType) UpdateSocials(id primitive.ObjectID, data models.ContactSocials) (*models.Contact, error) {
	var updateQuery = bson.M{
		"$set": bson.M{
			"socials": data,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	var updatedContact models.Contact

	if err := c.Collection.FindOneAndUpdate(c.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&updatedContact); err != nil {
		return nil, err
	}

	return &updatedContact, nil
}
