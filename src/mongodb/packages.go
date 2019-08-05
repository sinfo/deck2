package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"go.mongodb.org/mongo-driver/bson"
)

type PackagesType struct {
	Collection *mongo.Collection
	Context    context.Context
}

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

	return nil
}

// CreatePackage creates a new package.
func (p *PackagesType) CreatePackage(data CreatePackageData) (*models.Package, error) {

	var newPackage models.Package

	var query = bson.M{
		"name":  *data.Name,
		"items": *data.Items,
		"price": *data.Price,
		"vat":   *data.VAT,
	}

	insertResult, err := p.Collection.InsertOne(p.Context, query)

	if err != nil {
		log.Fatal(err)
	}

	if err := p.Collection.FindOne(p.Context, bson.M{"_id": insertResult.InsertedID}).Decode(&newPackage); err != nil {
		log.Println("Error finding created package:", err)
		return nil, err
	}

	return &newPackage, nil
}

// GetPackage gets a package by its ID
func (p *PackagesType) GetPackage(packageID primitive.ObjectID) (*models.Package, error) {
	var result models.Package

	err := p.Collection.FindOne(p.Context, bson.M{"_id": packageID}).Decode(&result)
	if err != nil {
		return nil, err
	}

	return &result, nil
}
