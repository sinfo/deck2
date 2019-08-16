package router

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
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

type addCommentToThreadData struct {
	Text *string `json:"text"`
}

func (acttd *addCommentToThreadData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(acttd); err != nil {
		return err
	}

	if acttd.Text == nil {
		return errors.New("invalid text")
	}

	return nil
}

func addCommentToThread(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	threadID, _ := primitive.ObjectIDFromHex(params["id"])

	var acttd = &addCommentToThreadData{}

	if err := acttd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	// create the post first
	var cpd = mongodb.CreatePostData{
		Member: credentials.ID,
		Text:   *acttd.Text,
	}

	newPost, err := mongodb.Posts.CreatePost(cpd)

	if err != nil {
		http.Error(w, "Could not create post", http.StatusExpectationFailed)
		return
	}

	// now adding to the thread
	updatedThread, err := mongodb.Threads.AddCommentToThread(threadID, newPost.ID)
	if err != nil {
		http.Error(w, "Could not add post to thread", http.StatusExpectationFailed)

		// clean up the created post
		if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
			log.Printf("error deleting post: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedThread)
}
