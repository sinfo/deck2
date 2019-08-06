package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
	"gotest.tools/assert"
)

var (
	TimeBefore = time.Now().Add(-time.Hour * 10)
	TimeNow    = time.Now()
	TimeAfter  = time.Now().Add(time.Hour * 10)
	Event1     = models.Event{ID: 1, Name: "SINFO1"}
	Event2     = models.Event{ID: 2, Name: "SINFO2", Begin: &TimeBefore, End: &TimeNow}
	Event3     = models.Event{ID: 3, Name: "SINFO3", Begin: &TimeNow, End: &TimeAfter}
	Meeting    = models.Meeting{Begin: TimeNow, End: TimeAfter, Place: "some place"}
)

func containsEvent(events []models.Event, event models.Event) bool {
	for _, s := range events {
		if s.ID == event.ID && s.Name == event.Name {
			return true
		}
	}

	return false
}

func containsPublicEvent(events []models.EventPublic, event models.Event) bool {
	for _, s := range events {
		if s.ID == event.ID && s.Name == event.Name {
			return true
		}
	}

	return false
}

func TestGetEvents(t *testing.T) {

	log.Println("testing events")

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event

	res, err := executeRequest("GET", "/events", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), true)
	assert.Equal(t, containsEvent(events, Event2), true)
}

func TestGetPublicEvents(t *testing.T) {

	log.Println("testing events")

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var events []models.EventPublic

	res, err := executeRequest("GET", "/public/events", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsPublicEvent(events, Event1), true)
	assert.Equal(t, containsPublicEvent(events, Event2), true)
}

func TestGetEventsByName(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?name=" + url.QueryEscape(Event1.Name)

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), true)
	assert.Equal(t, containsEvent(events, Event2), false)
}

func TestGetEventsBeforeDate(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event2.ID, "name": Event2.Name, "begin": Event2.Begin, "end": Event2.End}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event3.ID, "name": Event3.Name, "begin": Event3.Begin, "end": Event3.End}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?before=" + url.QueryEscape(Event3.Begin.Format(time.RFC3339))

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), false)
	assert.Equal(t, containsEvent(events, Event2), true)
	assert.Equal(t, containsEvent(events, Event3), false)
}

func TestGetEventsAfterDate(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event2.ID, "name": Event2.Name, "begin": Event2.Begin, "end": Event2.End}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event3.ID, "name": Event3.Name, "begin": Event3.Begin, "end": Event3.End}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?after=" + url.QueryEscape(Event2.End.Format(time.RFC3339))

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), false)
	assert.Equal(t, containsEvent(events, Event2), false)
	assert.Equal(t, containsEvent(events, Event3), true)
}

func TestGetEventsDuringDate(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event2.ID, "name": Event2.Name, "begin": Event2.Begin, "end": Event2.End}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{
		"_id": Event3.ID, "name": Event3.Name, "begin": Event3.Begin, "end": Event3.End}); err != nil {
		log.Fatal(err)
	}

	var events []models.Event
	var query = "?during=" + url.QueryEscape(Event3.Begin.Add(time.Hour).Format(time.RFC3339))

	res, err := executeRequest("GET", "/events"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&events)

	assert.Equal(t, containsEvent(events, Event1), false)
	assert.Equal(t, containsEvent(events, Event2), false)
	assert.Equal(t, containsEvent(events, Event3), true)
}

func TestGetEventsBadQuery(t *testing.T) {

	var badQuery1 = "?before=wrong"
	var badQuery2 = "?after=wrong"
	var badQuery3 = "?during=wrong"

	res1, err1 := executeRequest("GET", "/events"+badQuery1, nil)
	res2, err2 := executeRequest("GET", "/events"+badQuery2, nil)
	res3, err3 := executeRequest("GET", "/events"+badQuery3, nil)
	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.NilError(t, err3)

	assert.Equal(t, res1.Code, http.StatusBadRequest)
	assert.Equal(t, res2.Code, http.StatusBadRequest)
	assert.Equal(t, res3.Code, http.StatusBadRequest)
}

func TestGetEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var event1, event2 models.Event

	res1, err1 := executeRequest("GET", fmt.Sprintf("/events/%v", Event1.ID), nil)
	res2, err2 := executeRequest("GET", fmt.Sprintf("/events/%v", Event2.ID), nil)
	assert.NilError(t, err1)
	assert.NilError(t, err2)
	assert.Equal(t, res1.Code, http.StatusOK)
	assert.Equal(t, res2.Code, http.StatusOK)

	json.NewDecoder(res1.Body).Decode(&event1)
	json.NewDecoder(res2.Body).Decode(&event2)

	assert.Equal(t, event1.ID, Event1.ID)
	assert.Equal(t, event2.ID, Event2.ID)
}

func TestGetEventBadID(t *testing.T) {

	res, err := executeRequest("GET", "/events/bad_ID", nil)
	assert.NilError(t, err)

	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestCreateEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var newEvent models.Event

	createEventData := &mongodb.CreateEventData{Name: Event2.Name}

	b, errMarshal := json.Marshal(createEventData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&newEvent)

	assert.Equal(t, newEvent.Name, Event2.Name)
}

func TestCreateEventInvalidName(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	createEventData := &mongodb.CreateEventData{Name: ""}

	b, errMarshal := json.Marshal(createEventData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	var future = TimeAfter.Add(time.Hour * 10)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event1.Name}); err != nil {
		log.Fatal(err)
	}

	var updatedEvent models.Event

	updateEventData := &mongodb.UpdateEventData{Name: Event3.Name, Begin: TimeAfter.UTC(), End: future.UTC()}

	b, errMarshal := json.Marshal(updateEventData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/events", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.Name, Event3.Name)
	assert.Equal(t, updatedEvent.Begin != nil, true)
	assert.Equal(t, updatedEvent.End != nil, true)
	assert.Equal(t, updatedEvent.Begin.Sub(TimeAfter).Seconds() < 10e-3, true) // millisecond precision
	assert.Equal(t, updatedEvent.End.Sub(future).Seconds() < 10e-3, true)      // millisecond precision
}

func TestUpdateEventIncompletePayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	type IncompletePayload struct {
		Name string
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event1.Name}); err != nil {
		log.Fatal(err)
	}

	updateEventData := IncompletePayload{Name: Event3.Name}

	b, errMarshal := json.Marshal(updateEventData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/events", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateEventWrongPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	type IncompletePayload struct {
		Name  string
		Begin string
		End   string
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event1.Name}); err != nil {
		log.Fatal(err)
	}

	updateEventData := IncompletePayload{Name: Event3.Name, Begin: "wrong", End: "dates"}

	b, errMarshal := json.Marshal(updateEventData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/events", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestDeleteEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event2.ID, "name": Event2.Name}); err != nil {
		log.Fatal(err)
	}

	var deletedEvent models.Event

	res, err := executeRequest("DELETE", fmt.Sprintf("/events/%v", Event2.ID), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&deletedEvent)

	assert.Equal(t, deletedEvent.ID, Event2.ID)

	events, _ := mongodb.Events.GetEvents(mongodb.GetEventsOptions{})
	assert.Equal(t, len(events), 1)
	assert.Equal(t, events[0].ID, Event1.ID)
}

func TestDeleteNonExistentEvent(t *testing.T) {

	res, err := executeRequest("DELETE", fmt.Sprintf("/events/%v", Event2.ID), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdateEventThemes(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	// Update dates.
	currentEvent, _ := mongodb.Events.GetCurrentEvent()
	var updateQuery = bson.M{"$set": bson.M{"begin": Event3.Begin, "end": Event3.End}}
	var filterQuery = bson.M{"_id": currentEvent.ID}
	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)
	mongodb.Events.Collection.FindOneAndUpdate(mongodb.Events.Context, filterQuery, updateQuery, optionsQuery).Decode(&currentEvent)

	// fill the themes
	var themes = []string{}
	days, err := currentEvent.DurationInDays()
	assert.NilError(t, err)
	for i := 0; i < days; i++ {
		themes = append(themes, strconv.Itoa(i))
	}

	var updatedEvent models.Event
	var uetd = mongodb.UpdateEventThemesData{Themes: &themes}
	b, errMarshal := json.Marshal(uetd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/events/themes", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, updatedEvent.Name, Event3.Name)
	for i := 0; i < days; i++ {
		assert.Equal(t, updatedEvent.Themes[i], themes[i])
	}
}
func TestUpdateEventThemesIncompletePayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	type IncompletePayload struct {
		Random string
	}

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	// Update dates.
	currentEvent, _ := mongodb.Events.GetCurrentEvent()
	var updateQuery = bson.M{"$set": bson.M{"begin": Event3.Begin, "end": Event3.End}}
	var filterQuery = bson.M{"_id": currentEvent.ID}
	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)
	mongodb.Events.Collection.FindOneAndUpdate(mongodb.Events.Context, filterQuery, updateQuery, optionsQuery).Decode(&currentEvent)

	// fill the themes
	var payload = IncompletePayload{Random: "somerandomname"}

	b, errMarshal := json.Marshal(payload)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/events/themes", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddPackageToEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Image:       Item.Image,
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

	newPackage, err := mongodb.Packages.CreatePackage(*createPackageData)
	assert.NilError(t, err)

	var publicName = "public name"

	aepd := &mongodb.AddEventPackageData{
		Template:   &newPackage.ID,
		PublicName: &publicName,
	}

	b, errMarshal := json.Marshal(aepd)
	assert.NilError(t, errMarshal)

	var updatedEvent models.Event
	currentEvent, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events/packages", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, updatedEvent.Name, Event3.Name)
	assert.Equal(t, len(updatedEvent.Packages) == 1, true)
	assert.Equal(t, updatedEvent.Packages[0].Available, true)
	assert.Equal(t, updatedEvent.Packages[0].PublicName, publicName)
	assert.Equal(t, updatedEvent.Packages[0].Template, newPackage.ID)
}

func TestAddPackageToEventPackageNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Image:       Item.Image,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	newItem, err := mongodb.Items.CreateItem(*createItemData)
	assert.NilError(t, err)

	Package.Items[0].Item = newItem.ID

	var publicName = "public name"
	var packageID = primitive.NewObjectID()

	aepd := &mongodb.AddEventPackageData{
		Template:   &packageID,
		PublicName: &publicName,
	}

	b, errMarshal := json.Marshal(aepd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events/packages", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddPackageToEventInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	type InvalidPayload struct {
		Name string `json:"name"`
	}

	aepd := &InvalidPayload{
		Name: "random name",
	}

	b, errMarshal := json.Marshal(aepd)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events/packages", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestRemovePackageFromEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Image:       Item.Image,
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

	newPackage, err := mongodb.Packages.CreatePackage(*createPackageData)
	assert.NilError(t, err)

	var publicName = "public name"

	addEventPackageData := &mongodb.AddEventPackageData{
		Template:   &newPackage.ID,
		PublicName: &publicName,
	}

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	currentEvent, err = mongodb.Events.AddPackage(currentEvent.ID, *addEventPackageData)
	assert.NilError(t, err)

	var updatedEvent models.Event

	res, err := executeRequest("DELETE", "/events/packages/"+newPackage.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, updatedEvent.Name, Event3.Name)
	assert.Equal(t, len(updatedEvent.Packages) == 0, true)
}

func TestUpdatePackageFromEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)
	defer mongodb.Packages.Collection.Drop(mongodb.Packages.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := &mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Image:       Item.Image,
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

	newPackage, err := mongodb.Packages.CreatePackage(*createPackageData)
	assert.NilError(t, err)

	var publicName = "public name"

	addEventPackageData := &mongodb.AddEventPackageData{
		Template:   &newPackage.ID,
		PublicName: &publicName,
	}

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	currentEvent, err = mongodb.Events.AddPackage(currentEvent.ID, *addEventPackageData)
	assert.NilError(t, err)

	var newPublicName = "new public name"
	var available = false

	var uped = mongodb.UpdateEventPackageData{
		PublicName: &newPublicName,
		Available:  &available,
	}

	b, errMarshal := json.Marshal(uped)
	assert.NilError(t, errMarshal)

	var updatedEvent models.Event

	res, err := executeRequest("PUT", "/events/packages/"+newPackage.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, updatedEvent.Name, Event3.Name)
	assert.Equal(t, len(updatedEvent.Packages) == 1, true)
	assert.Equal(t, updatedEvent.Packages[0].Template, newPackage.ID)
	assert.Equal(t, updatedEvent.Packages[0].PublicName, newPublicName)
	assert.Equal(t, updatedEvent.Packages[0].Available, available)
}

func TestAddItemToEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Image:       Item.Image,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	newItem, err := mongodb.Items.CreateItem(createItemData)
	assert.NilError(t, err)

	var updatedEvent models.Event
	var aeid = mongodb.AddEventItemData{ItemID: &newItem.ID}
	b, errMarshal := json.Marshal(aeid)
	assert.NilError(t, errMarshal)

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	res, err := executeRequest("POST", "/events/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, len(updatedEvent.Items) == 1, true)
	assert.Equal(t, updatedEvent.Items[0], newItem.ID)
}

func TestAddItemToEventInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Image:       Item.Image,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	newItem, err := mongodb.Items.CreateItem(createItemData)
	assert.NilError(t, err)

	type InvalidPayload struct {
		ItemID primitive.ObjectID `json:"id"`
	}

	var aeid = InvalidPayload{ItemID: newItem.ID}
	b, errMarshal := json.Marshal(aeid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddItemToEventItemNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	var itemID = primitive.NewObjectID()
	var aeid = mongodb.AddEventItemData{ItemID: &itemID}
	b, errMarshal := json.Marshal(aeid)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/events/items", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestRemoveItemFromEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Items.Collection.Drop(mongodb.Items.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	createItemData := mongodb.CreateItemData{
		Name:        Item.Name,
		Type:        Item.Type,
		Description: Item.Description,
		Image:       Item.Image,
		Price:       Item.Price,
		VAT:         Item.VAT,
	}

	newItem, err := mongodb.Items.CreateItem(createItemData)
	assert.NilError(t, err)

	var addEventItemData = mongodb.AddEventItemData{ItemID: &newItem.ID}

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	updatedEvent, err := mongodb.Events.AddItem(currentEvent.ID, addEventItemData)
	assert.NilError(t, err)

	res, err := executeRequest("DELETE", "/events/items/"+newItem.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, len(updatedEvent.Items) == 0, true)
}

func TestAddMeetingToEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	cmd := mongodb.CreateMeetingData{
		Begin: &Meeting.Begin,
		End:   &Meeting.End,
		Place: &Meeting.Place,
	}

	b, errMarshal := json.Marshal(cmd)
	assert.NilError(t, errMarshal)

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	var updatedEvent models.Event

	res, err := executeRequest("POST", "/events/meetings", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, len(updatedEvent.Meetings) == 1, true)

	createdMeeting, err := mongodb.Meetings.GetMeeting(updatedEvent.Meetings[0])
	assert.NilError(t, err)

	assert.Equal(t, createdMeeting.Begin.Sub(Meeting.Begin).Seconds() < 10e-3, true) // millisecond precision
	assert.Equal(t, createdMeeting.End.Sub(Meeting.End).Seconds() < 10e-3, true)     // millisecond precision
}

func TestRemoveMeetingFromEvent(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	cmd := mongodb.CreateMeetingData{
		Begin: &Meeting.Begin,
		End:   &Meeting.End,
		Place: &Meeting.Place,
	}

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	assert.NilError(t, err)

	newMeeting, err := mongodb.Meetings.CreateMeeting(cmd)
	assert.NilError(t, err)

	updatedEvent, err := mongodb.Events.AddMeeting(currentEvent.ID, newMeeting.ID)
	assert.NilError(t, err)

	res, err := executeRequest("DELETE", "/events/meetings/"+newMeeting.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedEvent)

	assert.Equal(t, updatedEvent.ID, currentEvent.ID)
	assert.Equal(t, len(updatedEvent.Meetings) == 0, true)

	_, err = mongodb.Meetings.GetMeeting(newMeeting.ID)
	assert.Equal(t, err != nil, true)
}

func TestRemoveMeetingFromEventMeetingNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Meetings.Collection.Drop(mongodb.Meetings.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	// Without this, because of previous tests, the variable currentEvent will be pointing to other event, different
	// from the event created on the line before this.
	if _, err := mongodb.Events.CreateEvent(mongodb.CreateEventData{Name: Event3.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("DELETE", "/events/meetings/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
