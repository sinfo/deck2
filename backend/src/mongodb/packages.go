package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"go.mongodb.org/mongo-driver/bson"
)

//PackagesType contains database information on Packages
type PackagesType struct {
	Collection *mongo.Collection
}

// CreatePackageData holds data needed to create a package
type CreatePackageData struct {
	Name  *string               `json:"name"`
	Items *[]models.PackageItem `json:"items"`
	Price *int                  `json:"price"`
	VAT   *int                  `json:"vat"`
}

// ParseBody fills the CreatePackageData from a body
func (cpd *CreatePackageData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cpd); err != nil {
		return err
	}

	if cpd.Name == nil || len(*cpd.Name) == 0 {
		return errors.New("invalid name")
	}

	if cpd.Price == nil || *cpd.Price < 0 {
		return errors.New("invalid price")
	}

	if cpd.VAT == nil || *cpd.VAT < 0 || *cpd.VAT > 100 {
		return errors.New("invalid vat")
	}

	if cpd.Items != nil && len(*cpd.Items) > 0 {
		for _, item := range *cpd.Items {
			if _, err := Items.GetItem(item.Item); err != nil {
				return errors.New("invalid item")
			}
		}
	}

	return nil
}

// CreatePackage creates a new package.
func (p *PackagesType) CreatePackage(data CreatePackageData) (*models.Package, error) {
	ctx = context.Background()

	var newPackage models.Package

	var query = bson.M{
		"name":  *data.Name,
		"price": *data.Price,
		"vat":   *data.VAT,
	}

	if data.Items != nil {
		query["items"] = *data.Items
	}

	insertResult, err := p.Collection.InsertOne(ctx, query)

	if err != nil {
		log.Fatal(err)
	}

	if err := p.Collection.FindOne(ctx, bson.M{"_id": insertResult.InsertedID}).Decode(&newPackage); err != nil {
		log.Println("Error finding created package:", err)
		return nil, err
	}

	return &newPackage, nil
}

// GetPackage gets a package by its ID
func (p *PackagesType) GetPackage(packageID primitive.ObjectID) (*models.Package, error) {
	ctx = context.Background()
	var result models.Package

	err := p.Collection.FindOne(ctx, bson.M{"_id": packageID}).Decode(&result)
	if err != nil {
		return nil, err
	}

	return &result, nil
}

// UpdatePackageItemsData is the structure used to updated a package's items
type UpdatePackageItemsData struct {
	Items *[]models.PackageItem `json:"items"`
}

// ParseBody fills the UpdatePackageItemsData from a body
func (upid *UpdatePackageItemsData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(upid); err != nil {
		return err
	}

	if upid.Items == nil {
		return errors.New("invalid items")
	}

	for _, packageItem := range *upid.Items {
		if packageItem.Quantity < 0 {
			return errors.New("invalid value for quantity: must be positive integer")
		}

		if _, err := Items.GetItem(packageItem.Item); err != nil {
			return errors.New("invalid item")
		}
	}

	return nil
}

// UpdatePackageItems updates the items of a package by id
func (p *PackagesType) UpdatePackageItems(packageID primitive.ObjectID, data UpdatePackageItemsData) (*models.Package, error) {
	ctx = context.Background()
	var result models.Package

	var updateQuery = bson.M{
		"$set": bson.M{
			"items": data.Items,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := p.Collection.FindOneAndUpdate(ctx, bson.M{"_id": packageID}, updateQuery, optionsQuery).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

// UpdatePackageData is the structure used to updated a package's items
type UpdatePackageData struct {
	Name  *string `json:"name"`
	Price *int    `json:"price"`
	VAT   *int    `json:"vat"`
}

// ParseBody fills the UpdatePackageData from a body
func (upd *UpdatePackageData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(upd); err != nil {
		return err
	}

	if upd.Name == nil {
		return errors.New("invalid name")
	}

	if upd.Price == nil || *upd.Price < 0 {
		return errors.New("invalid price")
	}

	if upd.VAT == nil || *upd.VAT < 0 || *upd.VAT > 100 {
		return errors.New("invalid vat")
	}

	return nil
}

// UpdatePackage updates the items of a package by id
func (p *PackagesType) UpdatePackage(packageID primitive.ObjectID, data UpdatePackageData) (*models.Package, error) {
	ctx = context.Background()
	var result models.Package

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":  *data.Name,
			"price": *data.Price,
			"vat":   *data.VAT,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := p.Collection.FindOneAndUpdate(ctx, bson.M{"_id": packageID}, updateQuery, optionsQuery).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

// DeletePackage deletes a package by its ID
func (p *PackagesType) DeletePackage(packageID primitive.ObjectID) (*models.Package, error) {
	ctx = context.Background()
	var result models.Package

	err := p.Collection.FindOneAndDelete(ctx, bson.M{"_id": packageID}).Decode(&result)
	if err != nil {
		return nil, err
	}

	return &result, nil
}

// GetPackagesOptions is the options to give to GetPackages.
// All the fields are optional, and as such we use pointers as a "hack" to deal
// with non-existent fields.
// The field is non-existent if it has a nil value.
// This filter will behave like a logical *and*.
type GetPackagesOptions struct {
	Name  *string
	Price *int
	VAT   *int
}

// GetPackages gets an array of packages
func (p *PackagesType) GetPackages(options GetPackagesOptions) ([]*models.Package, error) {
	ctx = context.Background()

	var packages = make([]*models.Package, 0)

	filter := bson.M{}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	if options.Price != nil {
		filter["price"] = options.Price
	}

	if options.VAT != nil {
		filter["vat"] = options.VAT
	}

	cur, err := p.Collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}

	for cur.Next(ctx) {

		// create a value into which the single document can be decoded
		var p models.Package
		err := cur.Decode(&p)
		if err != nil {
			return nil, err
		}

		packages = append(packages, &p)
	}

	if err := cur.Err(); err != nil {
		return nil, err
	}

	cur.Close(ctx)

	return packages, nil
}
