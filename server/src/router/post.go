package router

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
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

func updatePost(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	postID, _ := primitive.ObjectIDFromHex(params["id"])

	post, err := mongodb.Posts.GetPost(postID)

	if err != nil {
		http.Error(w, "Could not find post", http.StatusNotFound)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	if credentials.ID != post.Member && credentials.Role != models.RoleAdmin {
		http.Error(w, "Not the author of the post and not admin", http.StatusUnauthorized)
		return
	}

	var upd mongodb.UpdatePostData

	if err := upd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedPost, err := mongodb.Posts.UpdatePost(postID, upd)

	if err != nil {
		http.Error(w, "Could not update post", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedPost)

	// notify
	mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
		Kind: models.NotificationKindUpdated,
		Post: &updatedPost.ID,
	})
}
