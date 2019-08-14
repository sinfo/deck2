package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getPost(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	postID, _ := primitive.ObjectIDFromHex(params["id"])

	post, err := mongodb.Posts.GetPost(postID)

	if err != nil {
		http.Error(w, "Could not find post", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(post)
}
