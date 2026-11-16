package router

import (
	"strings"
	"time"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Only reconcile manually logged Gmail messages when identity is unambiguous.
// Notes, edited communications, approvals, comments, and short repeated replies
// must never be removed merely because their text resembles an email.
const manualGmailMatchWindow = 72 * time.Hour
const minBodyOnlyMatchLength = 40

type manualGmailCandidate struct {
	thread *models.Thread
	post   *models.Post
}

func normalizeGmailDuplicateText(text string) string {
	return strings.Join(strings.Fields(text), " ")
}

func matchesManualGmailMessage(
	message GmailMessageData,
	candidate manualGmailCandidate,
	memberID primitive.ObjectID,
) bool {
	thread, post := candidate.thread, candidate.post
	if thread.GmailMessageId != "" || thread.Meeting != nil ||
		len(thread.Comments) != 0 || thread.Status != models.ThreadStatusPending ||
		(thread.Channel != "" && thread.Channel != models.ThreadChannelGmail) ||
		post.Updated != nil || post.Member != memberID {
		return false
	}

	kind := models.ThreadKindFrom
	if message.IsOutgoing {
		kind = models.ThreadKindTo
	}
	if thread.Kind != kind {
		return false
	}

	sentAt, err := time.Parse(time.RFC3339, message.Date)
	if err != nil || thread.Posted.Sub(sentAt) > manualGmailMatchWindow ||
		sentAt.Sub(thread.Posted) > manualGmailMatchWindow {
		return false
	}

	body := normalizeGmailDuplicateText(message.Body)
	if body == "" {
		return false
	}
	manual := normalizeGmailDuplicateText(post.Text)
	formatted := normalizeGmailDuplicateText(formatGmailMessageText(message))

	// A verbatim header-and-body copy is more specific than body-only text.
	// A body-only match must be substantial to avoid merging "Thanks" replies.
	return (formatted != body && manual == formatted) ||
		(len([]rune(body)) >= minBodyOnlyMatchLength && manual == body)
}

// findManualGmailDuplicates searches only the participation being synchronized.
// If two manual entries match an email, or one entry matches multiple emails,
// keep all of them rather than guessing which one should be reconciled.
func findManualGmailDuplicates(
	messages []GmailMessageData,
	participationThreadIDs []primitive.ObjectID,
	memberID primitive.ObjectID,
) (map[string]*models.Thread, error) {
	matches := make(map[string]*models.Thread)
	if len(messages) == 0 || len(participationThreadIDs) == 0 {
		return matches, nil
	}

	threads, err := mongodb.Threads.GetThreadsByIDs(participationThreadIDs)
	if err != nil {
		return nil, err
	}

	candidates := make([]manualGmailCandidate, 0)
	postIDs := make([]primitive.ObjectID, 0)
	for _, thread := range threads {
		if thread.GmailMessageId != "" || thread.Meeting != nil ||
			len(thread.Comments) != 0 || thread.Status != models.ThreadStatusPending ||
			(thread.Channel != "" && thread.Channel != models.ThreadChannelGmail) ||
			(thread.Kind != models.ThreadKindTo && thread.Kind != models.ThreadKindFrom) {
			continue
		}
		postIDs = append(postIDs, thread.Entry)
		candidates = append(candidates, manualGmailCandidate{thread: thread})
	}

	posts, err := mongodb.Posts.GetPostsByIDs(postIDs)
	if err != nil {
		return nil, err
	}
	for index := range candidates {
		candidates[index].post = posts[candidates[index].thread.Entry]
	}

	used := make(map[primitive.ObjectID]int)
	seenMessages := make(map[string]bool)
	for _, message := range messages {
		if message.MessageId == "" || seenMessages[message.MessageId] {
			continue
		}
		seenMessages[message.MessageId] = true

		var candidate *models.Thread
		ambiguous := false
		for _, entry := range candidates {
			if entry.post == nil || !matchesManualGmailMessage(message, entry, memberID) {
				continue
			}
			if candidate != nil {
				ambiguous = true
				break
			}
			candidate = entry.thread
		}
		if !ambiguous && candidate != nil {
			matches[message.MessageId] = candidate
			used[candidate.ID]++
		}
	}

	for messageID, candidate := range matches {
		if used[candidate.ID] > 1 {
			delete(matches, messageID)
		}
	}
	return matches, nil
}
