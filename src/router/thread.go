package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getThread(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	threadID, _ := primitive.ObjectIDFromHex(params["id"])

	thread, err := mongodb.Threads.GetThread(threadID)

	if err != nil {
		http.Error(w, "Could not find thread", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(thread)
}
