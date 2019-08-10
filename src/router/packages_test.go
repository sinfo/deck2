package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"testing"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	Package = models.Package{
		Name:  "package1",
		Items: []models.PackageItem{models.PackageItem{Item: primitive.NewObjectID(), Quantity: 2}}, // set the item ID on item creation
		Price: 50,
		VAT:   24,
	}
)

func TestCreatePackage(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	newItem, err := mongodb.Items.CreateItem(*createItemData)
	assert.NilError(t, err)

	Package.Items[0].Item = newItem.ID

	createPackageData := &mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	var newPackage models.Package

	b, errMarshal := json.Marshal(createPackageData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/packages", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newPackage)

	assert.Equal(t, newPackage.Name, Package.Name)
	assert.Equal(t, len(newPackage.Items) == 1, true)
	assert.Equal(t, newPackage.Items[0].Item, Package.Items[0].Item)
	assert.Equal(t, newPackage.Items[0].Quantity, Package.Items[0].Quantity)
	assert.Equal(t, newPackage.Price, Package.Price)
	assert.Equal(t, newPackage.VAT, Package.VAT)
}

func TestCreatePackageInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	type InvalidPayload struct {
		Name string `json:"name"`
	}

	createPackageData := &InvalidPayload{
		Name: Item.Name,
	}

	b, errMarshal := json.Marshal(createPackageData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/packages", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestCreatePackageInvalidItemID(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	Package.Items[0].Item = primitive.NewObjectID()

	createPackageData := &mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	b, errMarshal := json.Marshal(createPackageData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/packages", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
