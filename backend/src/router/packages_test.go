package router

import (
	"bytes"
	"context"
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdatePackageItems(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	cpd := mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	newPackage, err := mongodb.Packages.CreatePackage(cpd)
	assert.NilError(t, err)

	cid := mongodb.CreateItemData{
		Name:        Item2.Name,
		Type:        Item2.Type,
		Description: Item2.Description,
		Price:       Item2.Price,
		VAT:         Item2.VAT,
	}

	newItem2, err := mongodb.Items.CreateItem(cid)
	assert.NilError(t, err)

	var newQuantity = 30

	var packageItems = []models.PackageItem{
		models.PackageItem{Item: newItem.ID, Quantity: Package.Items[0].Quantity},
		models.PackageItem{Item: newItem2.ID, Quantity: newQuantity},
	}

	var upid = mongodb.UpdatePackageItemsData{
		Items: &packageItems,
	}

	var updatedPackage models.Package

	b, errMarshal := json.Marshal(upid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/packages/"+newPackage.ID.Hex()+"/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedPackage)

	assert.Equal(t, updatedPackage.Name, Package.Name)
	assert.Equal(t, len(updatedPackage.Items) == 2, true)

	assert.Equal(t, updatedPackage.Items[0].Item, Package.Items[0].Item)
	assert.Equal(t, updatedPackage.Items[0].Quantity, Package.Items[0].Quantity)
	assert.Equal(t, updatedPackage.Items[1].Item, newItem2.ID)
	assert.Equal(t, updatedPackage.Items[1].Quantity, newQuantity)

	assert.Equal(t, updatedPackage.Price, Package.Price)
	assert.Equal(t, updatedPackage.VAT, Package.VAT)
}

func TestUpdatePackageItemsPackageIDNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var packageItems = []models.PackageItem{}

	var upid = mongodb.UpdatePackageItemsData{
		Items: &packageItems,
	}

	b, errMarshal := json.Marshal(upid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/packages/"+primitive.NewObjectID().Hex()+"/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdatePackageItemsInvalidItemID(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	cpd := mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	newPackage, err := mongodb.Packages.CreatePackage(cpd)
	assert.NilError(t, err)

	var newQuantity = 30

	var packageItems = []models.PackageItem{
		models.PackageItem{Item: newItem.ID, Quantity: Package.Items[0].Quantity},
		models.PackageItem{Item: primitive.NewObjectID(), Quantity: newQuantity},
	}

	var upid = mongodb.UpdatePackageItemsData{
		Items: &packageItems,
	}

	b, errMarshal := json.Marshal(upid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/packages/"+newPackage.ID.Hex()+"/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetPackages(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	cpd := mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	newPackage, err := mongodb.Packages.CreatePackage(cpd)
	assert.NilError(t, err)

	var packages []models.Package

	res, err := executeRequest("GET", "/packages", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&packages)

	assert.Equal(t, len(packages), 1)
	assert.Equal(t, packages[0].ID, newPackage.ID)
	assert.Equal(t, packages[0].Name, newPackage.Name)
	assert.Equal(t, packages[0].Price, newPackage.Price)
	assert.Equal(t, packages[0].VAT, newPackage.VAT)
}

func TestGetPackage(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	cpd := mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	newPackage, err := mongodb.Packages.CreatePackage(cpd)
	assert.NilError(t, err)

	var p models.Package

	res, err := executeRequest("GET", "/packages/"+newPackage.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&p)

	assert.Equal(t, p.ID, newPackage.ID)
	assert.Equal(t, p.Name, newPackage.Name)
	assert.Equal(t, p.Price, newPackage.Price)
	assert.Equal(t, p.VAT, newPackage.VAT)
}

func TestGetPackageNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/package/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdatePackage(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	cpd := mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	newPackage, err := mongodb.Packages.CreatePackage(cpd)
	assert.NilError(t, err)

	var newName = "new name"
	var newPrice = 800
	var newVAT = 71

	upd := mongodb.UpdatePackageData{
		Name:  &newName,
		Price: &newPrice,
		VAT:   &newVAT,
	}

	var updatedPackage models.Package

	b, errMarshal := json.Marshal(upd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/packages/"+newPackage.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedPackage)

	assert.Equal(t, updatedPackage.ID, newPackage.ID)
	assert.Equal(t, updatedPackage.Name, newName)
	assert.Equal(t, updatedPackage.Price, newPrice)
	assert.Equal(t, updatedPackage.VAT, newVAT)
}

func TestUpdatePackageInvalidPayload(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	cpd := mongodb.CreatePackageData{
		Name:  &Package.Name,
		Items: &Package.Items,
		Price: &Package.Price,
		VAT:   &Package.VAT,
	}

	newPackage, err := mongodb.Packages.CreatePackage(cpd)
	assert.NilError(t, err)

	type InvalidPayload struct {
		OtherField string
	}

	upd := InvalidPayload{
		OtherField: "some random stuff",
	}

	b, errMarshal := json.Marshal(upd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/packages/"+newPackage.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdatePackageNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Items.Collection.Drop(ctx)
	defer mongodb.Packages.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newName = "new name"
	var newPrice = 800
	var newVAT = 71

	upd := mongodb.UpdatePackageData{
		Name:  &newName,
		Price: &newPrice,
		VAT:   &newVAT,
	}

	b, errMarshal := json.Marshal(upd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/packages/"+primitive.NewObjectID().Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
