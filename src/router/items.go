package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func createItem(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var cid = &mongodb.CreateItemData{}

	if err := cid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newItem, err := mongodb.Items.CreateItem(*cid)

	if err != nil {
		http.Error(w, "Could not create item", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newItem)
}

func getItem(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	item, err := mongodb.Items.GetItem(id)

	if err != nil {
		http.Error(w, "Could not find item", http.StatusNotFound)
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
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedItem, err := mongodb.Items.UpdateItem(id, *uid)

	if err != nil {
		http.Error(w, "Could not update item", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedItem)
}
