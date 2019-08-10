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
	Event = models.Event{ID: 1, Name: "SINFO1"}
	Item  = models.Item{Name: "item1", Type: "item_type", Description: "item_description", Image: "", Price: 50, VAT: 24}
	Item2 = models.Item{Name: "item2", Type: "item_type_2", Description: "item_description_2", Image: "", Price: 55, VAT: 25}
)

func TestCreateItem(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newItem models.Item

	createItemData := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	b, errMarshal := json.Marshal(createItemData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newItem)

	assert.Equal(t, newItem.Name, Item.Name)
	assert.Equal(t, newItem.Description, Item.Description)
	assert.Equal(t, newItem.Price, Item.Price)
	assert.Equal(t, newItem.VAT, Item.VAT)
}

func TestCreateItemInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	type InvalidPayload struct {
		Name string `json:"name"`
	}

	createItemData := &InvalidPayload{
		Name: Item.Name,
	}

	b, errMarshal := json.Marshal(createItemData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestGetItem(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	cid := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	createdItem, err := mongodb.Items.CreateItem(*cid)
	assert.NilError(t, err)

	var newItem models.Item

	res, err := executeRequest("GET", "/items/"+createdItem.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newItem)

	assert.Equal(t, newItem.Name, Item.Name)
	assert.Equal(t, newItem.Description, Item.Description)
	assert.Equal(t, newItem.Price, Item.Price)
	assert.Equal(t, newItem.VAT, Item.VAT)
}

func TestGetItems(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	cid := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	_, err := mongodb.Items.CreateItem(*cid)
	assert.NilError(t, err)

	var items []models.Item

	res, err := executeRequest("GET", "/items", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&items)

	assert.Equal(t, len(items) == 1, true)
	assert.Equal(t, items[0].Name, Item.Name)
	assert.Equal(t, items[0].Description, Item.Description)
	assert.Equal(t, items[0].Price, Item.Price)
	assert.Equal(t, items[0].VAT, Item.VAT)
}

func TestUpdateItem(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	cid := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	createdItem, err := mongodb.Items.CreateItem(*cid)
	assert.NilError(t, err)

	uid := mongodb.UpdateItemData{
		Name:        "new name",
		Type:        "new type",
		Description: "new description",
		Price:       3,
		VAT:         46,
	}

	b, errMarshal := json.Marshal(uid)
	assert.NilError(t, errMarshal)

	var updatedItem models.Item

	res, err := executeRequest("PUT", "/items/"+createdItem.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedItem)

	assert.Equal(t, updatedItem.ID, createdItem.ID)
	assert.Equal(t, updatedItem.Name, uid.Name)
	assert.Equal(t, updatedItem.Description, uid.Description)
	assert.Equal(t, updatedItem.Price, uid.Price)
	assert.Equal(t, updatedItem.VAT, uid.VAT)
}

func TestUpdateItemNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	uid := mongodb.UpdateItemData{
		Name:        "new name",
		Type:        "new type",
		Description: "new description",
		Price:       3,
		VAT:         46,
	}

	b, errMarshal := json.Marshal(uid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/items/"+primitive.NewObjectID().Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
