package router

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type GmailMessageData struct {
	MessageId  string `json:"messageId"`
	ThreadId   string `json:"threadId"`
	Subject    string `json:"subject"`
	From       string `json:"from"`
	To         string `json:"to"`
	Date       string `json:"date"`
	Body       string `json:"body"`
	IsOutgoing bool   `json:"isOutgoing"`
}

type syncGmailMessagesData struct {
	Messages []GmailMessageData `json:"messages"`
	Event    *int               `json:"event"`
}

func (sgmd *syncGmailMessagesData) ParseBody(body io.Reader) error {
	if err := json.NewDecoder(body).Decode(sgmd); err != nil {
		return err
	}
	return nil
}

// formatGmailMessageText prepends structured metadata headers (📧 Subject, De, Para)
// to the message text, which the frontend parses to render dedicated email card headers.
func formatGmailMessageText(msg GmailMessageData) string {
	var headerLines []string
	if msg.Subject != "" && msg.Subject != "(No subject)" {
		headerLines = append(headerLines, fmt.Sprintf("📧 %s", msg.Subject))
	}
	if msg.From != "" {
		headerLines = append(headerLines, fmt.Sprintf("De: %s", msg.From))
	}
	if msg.To != "" {
		headerLines = append(headerLines, fmt.Sprintf("Para: %s", msg.To))
	}

	if len(headerLines) > 0 {
		return fmt.Sprintf("%s\n\n%s", strings.Join(headerLines, "\n"), msg.Body)
	}
	return msg.Body
}

var syncGmailMutex sync.Mutex

// syncGmailMessagesToThreads processes a batch of Gmail messages:
// - Deduplicates against existing threads in MongoDB via GmailMessageId
// - Skips duplicates within the current incoming batch
// - Preserves message timestamps and direction (From/To)
// - Creates post and thread records, linking them via the attachThread callback
func syncGmailMessagesToThreads(
	messages []GmailMessageData,
	memberID primitive.ObjectID,
	attachThread func(threadID primitive.ObjectID) error,
) int {
	syncGmailMutex.Lock()
	defer syncGmailMutex.Unlock()

	messageIds := make([]string, 0, len(messages))
	for _, msg := range messages {
		if msg.MessageId != "" {
			messageIds = append(messageIds, msg.MessageId)
		}
	}
	existingThreads, err := mongodb.Threads.GetThreadsByGmailMessageIds(messageIds)
	if err != nil {
		log.Println("Error checking existing gmail threads:", err)
	}

	processedMessageIds := make(map[string]bool)
	var syncedCount int

	for _, msg := range messages {
		if msg.MessageId == "" {
			continue
		}

		if _, exists := existingThreads[msg.MessageId]; exists {
			continue
		}
		if processedMessageIds[msg.MessageId] {
			continue
		}
		processedMessageIds[msg.MessageId] = true

		var postedTime *time.Time
		if msg.Date != "" {
			if parsed, err := time.Parse(time.RFC3339, msg.Date); err == nil {
				postedTime = &parsed
			}
		}

		kind := models.ThreadKindFrom
		if msg.IsOutgoing {
			kind = models.ThreadKindTo
		}

		formattedText := formatGmailMessageText(msg)

		cpd := mongodb.CreatePostData{
			Member: memberID,
			Text:   formattedText,
		}

		newPost, err := mongodb.Posts.CreatePost(cpd)
		if err != nil {
			log.Printf("Error creating post for gmail message %s: %s", msg.MessageId, err)
			continue
		}

		ctd := mongodb.CreateThreadData{
			Entry:          newPost.ID,
			Kind:           kind,
			GmailMessageId: msg.MessageId,
			GmailThreadId:  msg.ThreadId,
			Posted:         postedTime,
		}

		newThread, err := mongodb.Threads.CreateThread(ctd)
		if err != nil {
			log.Printf("Error creating thread for gmail message %s: %s", msg.MessageId, err)
			mongodb.Posts.DeletePost(newPost.ID)
			continue
		}

		if err := attachThread(newThread.ID); err != nil {
			log.Printf("Error attaching thread for gmail message %s: %s", msg.MessageId, err)
			mongodb.Posts.DeletePost(newPost.ID)
			mongodb.Threads.DeleteThread(newThread.ID)
			continue
		}

		syncedCount++
	}

	return syncedCount
}

func getThread(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	threadID, _ := primitive.ObjectIDFromHex(params["id"])

	thread, err := mongodb.Threads.GetThread(threadID)

	if err != nil {
		http.Error(w, "Could not find thread: "+err.Error(), http.StatusNotFound)
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
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
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
		http.Error(w, "Could not create post: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	// now adding to the thread
	updatedThread, err := mongodb.Threads.AddCommentToThread(threadID, newPost.ID)
	if err != nil {
		http.Error(w, "Could not add post to thread: "+err.Error(), http.StatusExpectationFailed)

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
		http.Error(w, "Thread not found: "+err.Error(), http.StatusNotFound)
		return
	}

	if _, err := mongodb.Posts.GetPost(postID); err != nil {
		http.Error(w, "Post not found: "+err.Error(), http.StatusNotFound)
		return
	}

	updatedThread, err := mongodb.Threads.RemoveCommentFromThread(threadID, postID)
	if err != nil {
		http.Error(w, "Could not remove post from thread: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	if _, err := mongodb.Posts.DeletePost(postID); err != nil {
		http.Error(w, "Could not delete post: "+err.Error(), http.StatusExpectationFailed)

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
			http.Error(w, "Thread not found: "+err.Error(), http.StatusNotFound)
			return
		}

		p, err := mongodb.Posts.GetPost(t.Entry)
		if err != nil {
			log.Println("getPost")
			http.Error(w, "Post not found: "+err.Error(), http.StatusNotFound)
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
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	thread, err := mongodb.Threads.UpdateThread(id, utd)

	if err != nil {
		http.Error(w, "Could not find thread or meeting: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(thread)
}

func deleteThread(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid thread id", http.StatusBadRequest)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)
	if !ok {
		http.Error(w, "Authentication failed", http.StatusUnauthorized)
		return
	}

	t, err := mongodb.Threads.GetThread(id)
	if err != nil {
		http.Error(w, "Thread not found: "+err.Error(), http.StatusNotFound)
		return
	}

	p, err := mongodb.Posts.GetPost(t.Entry)
	if err != nil {
		http.Error(w, "Post not found: "+err.Error(), http.StatusNotFound)
		return
	}

	if credentials.Role.AccessLevel() != 0 && p.Member != credentials.ID {
		http.Error(w, "Unauthorized", http.StatusForbidden)
		return
	}

	thread, err := mongodb.Threads.DeleteThread(id)
	if err != nil {
		http.Error(w, "Could not delete thread: "+err.Error(), http.StatusNotFound)
		return
	}

	_ = json.NewEncoder(w).Encode(thread)
}
