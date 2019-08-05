package router

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
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
