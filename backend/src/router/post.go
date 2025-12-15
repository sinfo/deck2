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
		http.Error(w, "Could not find post: " + err.Error(), http.StatusNotFound)
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
		http.Error(w, "Could not find post: " + err.Error(), http.StatusNotFound)
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
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedPost, err := mongodb.Posts.UpdatePost(postID, upd)

	if err != nil {
		http.Error(w, "Could not update post: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// attempt to enrich response with thread and actor (speaker/company)
	var threadID *primitive.ObjectID
	var speakerID *primitive.ObjectID
	var companyID *primitive.ObjectID

	if thread, terr := mongodb.Threads.FindByPost(updatedPost.ID); terr == nil && thread != nil {
		threadID = &thread.ID

		// try to find owning speaker/company for this thread
		if sp, _ := mongodb.Speakers.FindThread(thread.ID); sp != nil {
			sid := sp.ID
			speakerID = &sid
		}
		if co, _ := mongodb.Companies.FindThread(thread.ID); co != nil && speakerID == nil {
			cid := co.ID
			companyID = &cid
		}
	}

	// build response payload keeping backward compatibility intent minimal
	resp := map[string]interface{}{
		"post": updatedPost,
	}
	if threadID != nil {
		resp["thread"] = threadID.Hex()
	}
	if speakerID != nil {
		resp["speaker"] = speakerID.Hex()
	}
	if companyID != nil {
		resp["company"] = companyID.Hex()
	}

	json.NewEncoder(w).Encode(resp)

	// notify with enriched context so notifications have thread/actor
	notif := mongodb.CreateNotificationData{
		Kind:   models.NotificationKindUpdated,
		Post:   &updatedPost.ID,
		Thread: threadID,
	}
	if speakerID != nil {
		notif.Speaker = speakerID
	}
	if companyID != nil {
		notif.Company = companyID
	}

	mongodb.Notifications.Notify(credentials.ID, notif)
}
