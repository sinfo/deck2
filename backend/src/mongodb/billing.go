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

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson"
)

// BillingsType stores importat db information on contacts
type BillingsType struct {
	Collection *mongo.Collection
}

// GetBillingsOptions is used as a filter on getBillings
type GetBillingsOptions struct {
	After            *time.Time          `json:"after" bson:"after"`
	Before           *time.Time          `json:"before" bson:"before"`
	ValueGreaterThan *int                `json:"valueGreaterThan" bson:"valueGreaterThan"`
	ValueLessThan    *int                `json:"valueLessThan" bson:"valueLessThan"`
	Event            *int                `json:"event" bson:"event"`
	Company          *primitive.ObjectID `json:"company" bson:"company"`
	Role             *models.TeamRole
}

// CreateStatusData stores status information on created billing
type CreateStatusData struct {
	Invoice  *bool `json:"invoice" bson:"invoice"`
	Paid     *bool `json:"paid" bson:"paid"`
	ProForma *bool `json:"proForma" bson:"proForma"`
	Receipt  *bool `json:"receipt" bson:"receipt"`
}

// CreateBillingData stores all information needed to create a billing
type CreateBillingData struct {
	Status        *CreateStatusData   `json:"status" bson:"status"`
	Event         *int                `json:"event" bson:"event"`
	Company       *primitive.ObjectID `json:"company" bson:"company"`
	Value         *int                `json:"value" bson:"value"`
	InvoiceNumber *string             `json:"invoiceNumber" bson:"invoiceNumber"`
	Emission      *time.Time          `json:"emission" bson:"emission"`
	Notes         *string             `json:"notes" bson:"notes"`
	Visible       *bool               `json:"visible" bson:"visible"`
}

// ParseBody fills a CreateBillingData struct with data
func (cbd *CreateBillingData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cbd); err != nil {
		return err
	}

	if cbd.Status == nil {
		return errors.New("invalid status")
	}

	if cbd.Status.Invoice == nil {
		return errors.New("invalid invoice")
	}

	if cbd.Status.Paid == nil {
		return errors.New("invalid paid")
	}

	if cbd.Status.ProForma == nil {
		return errors.New("invalid proforma")
	}

	if cbd.Status.Receipt == nil {
		return errors.New("invalid receipt")
	}

	if cbd.Value == nil || *cbd.Value < 0 {
		return errors.New("invalid value")
	}

	if cbd.InvoiceNumber == nil || len(*cbd.InvoiceNumber) == 0 {
		return errors.New("invalid invoice number")
	}

	if cbd.Emission == nil {
		return errors.New("invalid emission time")
	}

	if cbd.Event == nil {
		return errors.New("invalid event")
	}

	return nil
}

// GetBillings gets all billings based on a filter
func (b *BillingsType) GetBillings(options GetBillingsOptions) ([]*models.Billing, error) {
	ctx = context.Background()

	var billings = make([]*models.Billing, 0)

	var err error

	filter := bson.M{}

	if options.Role != nil {
		if options.Role.AccessLevel() > 1 {
			filter["visible"] = true
		}
	}

	if options.Before != nil {
		filter["emission"] = bson.M{"$lt": *options.Before}
	}

	if options.After != nil {
		filter["emission"] = bson.M{"$gt": *options.After}
	}

	if options.ValueGreaterThan != nil {
		filter["value"] = bson.M{"$gt": *options.ValueGreaterThan}
	}

	if options.ValueLessThan != nil {
		filter["value"] = bson.M{"$lt": *options.ValueLessThan}
	}

	if options.Company != nil {
		filter["company"] = *options.Company
	}

	if options.Event != nil {
		filter["event"] = *options.Event
	}

	if options.Company != nil {
		filter["company"] = *options.Company
	}

	curr, err := b.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for curr.Next(ctx) {
		var billing models.Billing

		if err := curr.Decode(&billing); err != nil {
			return nil, err
		}

		billings = append(billings, &billing)
	}

	curr.Close(ctx)

	return billings, nil

}

// GetBilling returns a single billing based on id
func (b *BillingsType) GetBilling(id primitive.ObjectID) (*models.Billing, error) {
	var billing models.Billing
	ctx := context.Background()

	if err := b.Collection.FindOne(ctx, bson.M{"_id": id}).Decode(&billing); err != nil {
		return nil, err
	}

	return &billing, nil
}

// CreateBilling creates a new billing
func (b *BillingsType) CreateBilling(data CreateBillingData) (*models.Billing, error) {

	ctx := context.Background()

	var insertData = bson.M{
		"status": bson.M{
			"invoice":  *data.Status.Invoice,
			"paid":     *data.Status.Paid,
			"proForma": *data.Status.ProForma,
			"receipt":  *data.Status.Receipt,
		},
		"event":         *data.Event,
		"value":         *data.Value,
		"invoiceNumber": *data.InvoiceNumber,
		"emission":      *data.Emission,
		"notes":         *data.Notes,
	}

	if data.Company != nil {
		insertData["company"] = *data.Company
	}

	if data.Visible != nil {
		insertData["visible"] = *data.Visible
	}

	insertResult, err := b.Collection.InsertOne(ctx, insertData)

	if err != nil {
		return nil, err
	}

	newBilling, err := b.GetBilling(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created billing", err)
		return nil, err
	}

	return newBilling, nil
}

// UpdateBilling updates a billing
func (b *BillingsType) UpdateBilling(id primitive.ObjectID, data CreateBillingData) (*models.Billing, error) {

	ctx := context.Background()

	var billing models.Billing

	var updateQuery = bson.M{
		"$set": bson.M{
			"status": bson.M{
				"invoice":  *data.Status.Invoice,
				"paid":     *data.Status.Paid,
				"proForma": *data.Status.ProForma,
				"receipt":  *data.Status.Receipt,
			},
			"event":         *data.Event,
			"value":         *data.Value,
			"invoiceNumber": *data.InvoiceNumber,
			"emission":      *data.Emission,
			"notes":         *data.Notes,
			"company":       *data.Company,
			"visible":       *data.Visible,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := b.Collection.FindOneAndUpdate(ctx, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&billing); err != nil {
		return nil, err
	}

	return &billing, nil
}

//DeleteBilling deletes a billing and removes it from a company if associated with it
func (b *BillingsType) DeleteBilling(id primitive.ObjectID) (*models.Billing, error) {
	ctx := context.Background()

	billing, err := b.GetBilling(id)
	if err != nil {
		return billing, err
	}

	deleteResult, err := b.Collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return billing, err
	}

	if deleteResult.DeletedCount != 1 {
		return billing, fmt.Errorf("should have deleted 1 billing, deleted %v", deleteResult.DeletedCount)
	}

	return billing, nil
}
