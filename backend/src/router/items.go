package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/h2non/filetype"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/spaces"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func createItem(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var cid = &mongodb.CreateItemData{}

	if err := cid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newItem, err := mongodb.Items.CreateItem(*cid)

	if err != nil {
		http.Error(w, "Could not create item: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newItem)
}

func getItems(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetItemsOptions{}

	name := urlQuery.Get("name")
	_type := urlQuery.Get("type")

	if len(name) > 0 {
		options.Name = &name
	}

	if len(_type) > 0 {
		options.Type = &_type
	}

	items, err := mongodb.Items.GetItems(options)

	if err != nil {
		http.Error(w, "Could not get items: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(items)
}

func getItem(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	item, err := mongodb.Items.GetItem(id)

	if err != nil {
		http.Error(w, "Could not find item: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(item)
}

func updateItem(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	var uid = &mongodb.UpdateItemData{}

	if err := uid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedItem, err := mongodb.Items.UpdateItem(id, *uid)

	if err != nil {
		http.Error(w, "Could not update item: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedItem)
}

func deleteItem(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	item, err := mongodb.Items.DeleteItem(id)
	if err != nil {
		http.Error(w, "Could not find item: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(item)
}

func uploadItemImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	itemID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Items.GetItem(itemID); err != nil {
		http.Error(w, "Invalid item ID: " + err.Error(), http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
		http.Error(w, fmt.Sprintf("Error parsing form: %v", err.Error()), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload: " + err.Error(), http.StatusBadRequest)
		return
	}

	log.Println("File size", handler.Size)

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > config.ImageMaxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image: " + err.Error(), http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadItemImage(currentEvent.ID, itemID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedItem, err := mongodb.Items.UpdateItemImage(itemID, *url)
	if err != nil {
		http.Error(w, "Couldn't update item image: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedItem)
}
