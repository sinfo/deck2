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

	//notify

	cnd := mongodb.CreateNotificationData{
		Kind:   models.NotificationKindCreated,
		Thread: &updatedThread.ID,
		Post:   &newPost.ID,
	}

	speaker, err := mongodb.Speakers.FindThread(threadID)
	if err != nil {
		log.Println("error finding thread: " + err.Error())
		return
	} else if speaker != nil {
		cnd.Speaker = &speaker.ID
		mongodb.Notifications.Notify(credentials.ID, cnd)
		return
	}

	company, err := mongodb.Companies.FindThread(threadID)
	if err != nil {
		log.Println("error finding thread: " + err.Error())
		return
	} else if company != nil {
		cnd.Company = &company.ID
		mongodb.Notifications.Notify(credentials.ID, cnd)
		return
	}

	meeting, err := mongodb.Meetings.FindThread(threadID)
	if err != nil {
		log.Println("error finding thread: " + err.Error())
		return
	} else if meeting != nil {
		cnd.Meeting = &meeting.ID
		mongodb.Notifications.Notify(credentials.ID, cnd)
		return
	}
}

func removeCommentFromThread(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	threadID, _ := primitive.ObjectIDFromHex(params["threadID"])
	postID, _ := primitive.ObjectIDFromHex(params["postID"])

	if _, err := mongodb.Threads.GetThread(threadID); err != nil {
		http.Error(w, "Thread not found", http.StatusNotFound)
		return
	}

	if _, err := mongodb.Posts.GetPost(postID); err != nil {
		http.Error(w, "Post not found", http.StatusNotFound)
		return
	}

	updatedThread, err := mongodb.Threads.RemoveCommentFromThread(threadID, postID)
	if err != nil {
		http.Error(w, "Could not remove post from thread", http.StatusExpectationFailed)
		return
	}

	if _, err := mongodb.Posts.DeletePost(postID); err != nil {
		http.Error(w, "Could not delete post", http.StatusExpectationFailed)

		// add the not deleted post to the thread again
		if _, err := mongodb.Threads.AddCommentToThread(threadID, postID); err != nil {
			log.Printf("error re-adding post to thread: %s\n", err.Error())
		}
	}

	json.NewEncoder(w).Encode(updatedThread)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:   models.NotificationKindDeleted,
			Thread: &updatedThread.ID,
			Post:   &postID,
		})
	}
}

func updateThread(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		t, err := mongodb.Threads.GetThread(id)
		if err != nil {
			log.Println("getThread")
			http.Error(w, "Thread not found", http.StatusNotFound)
			return
		}

		p, err := mongodb.Posts.GetPost(t.Entry)
		if err != nil {
			log.Println("getPost")
			http.Error(w, "Post not found", http.StatusNotFound)
			return
		}

		if credentials.Role.AccessLevel() != 0 && p.Member != credentials.ID {
			http.Error(w, "Unauthorized", http.StatusForbidden)
			return
		}
	} else {
		http.Error(w, "Authentication failed", http.StatusUnauthorized)
		return
	}

	var utd = mongodb.UpdateThreadData{}

	if err := utd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	thread, err := mongodb.Threads.UpdateThread(id, utd)

	if err != nil {
		http.Error(w, "Could not find thread or meeting", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(thread)
}

func deleteThread(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		t, err := mongodb.Threads.GetThread(id)
		if err != nil {
			http.Error(w, "Thread not found", http.StatusNotFound)
			return
		}

		for _, commentID := range t.Comments {
			_, err = mongodb.Posts.DeletePost(commentID)
			if err != nil {
				http.Error(w, "Post not found. Thread was not deleted.", http.StatusNotFound)
				return
			}
		}

		if credentials.Role.AccessLevel() != 0 {
			http.Error(w, "Unauthorized", http.StatusForbidden)
			return
		}
	} else {
		http.Error(w, "Authentication failed", http.StatusUnauthorized)
		return
	}

	thread, err := mongodb.Threads.DeleteThread(id)

	if err != nil {
		http.Error(w, "Could not find thread", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(thread)
}
