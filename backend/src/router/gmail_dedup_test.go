package router

import (
	"testing"
	"time"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func TestMatchesManualGmailMessage(t *testing.T) {
	memberID := primitive.NewObjectID()
	sentAt := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	message := GmailMessageData{
		MessageId:  "gmail-message-id",
		ThreadId:   "gmail-thread-id",
		Subject:    "SINFO 34 invitation",
		From:       "member@sinfo.org",
		To:         "contact@example.com",
		Date:       sentAt.Format(time.RFC3339),
		Body:       "Hello, we would like to invite your team to participate in our next SINFO edition.",
		IsOutgoing: true,
	}
	base := manualGmailCandidate{
		thread: &models.Thread{
			ID:      primitive.NewObjectID(),
			Entry:   primitive.NewObjectID(),
			Kind:    models.ThreadKindTo,
			Channel: models.ThreadChannelGmail,
			Status:  models.ThreadStatusPending,
			Posted:  sentAt.Add(time.Hour),
		},
		post: &models.Post{
			Member: memberID,
			Text:   message.Body,
		},
	}

	cases := []struct {
		name string
		edit func(*manualGmailCandidate, *GmailMessageData)
		want bool
	}{
		{"body copied exactly", nil, true},
		{"complete email copied", func(c *manualGmailCandidate, m *GmailMessageData) {
			c.post.Text = formatGmailMessageText(*m)
		}, true},
		{"manually logged before sending", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.thread.Posted = sentAt.Add(-2 * time.Hour)
		}, true},
		{"different message", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.post.Text = "I discussed the speaker invitation by phone and will follow up."
		}, false},
		{"different member", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.post.Member = primitive.NewObjectID()
		}, false},
		{"wrong direction", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.thread.Kind = models.ThreadKindFrom
		}, false},
		{"non-Gmail channel", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.thread.Channel = models.ThreadChannelLinkedIn
		}, false},
		{"already linked", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.thread.GmailMessageId = "previous-id"
		}, false},
		{"approved", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.thread.Status = models.ThreadStatusApproved
		}, false},
		{"commented", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.thread.Comments = []primitive.ObjectID{primitive.NewObjectID()}
		}, false},
		{"edited", func(c *manualGmailCandidate, _ *GmailMessageData) {
			updated := time.Now().UTC()
			c.post.Updated = &updated
		}, false},
		{"outside the time window", func(c *manualGmailCandidate, _ *GmailMessageData) {
			c.thread.Posted = sentAt.Add(5 * 24 * time.Hour)
		}, false},
		{"unparseable Gmail date", func(_ *manualGmailCandidate, m *GmailMessageData) {
			m.Date = ""
		}, false},
		{"short repeated reply is not enough", func(c *manualGmailCandidate, m *GmailMessageData) {
			m.Body = "Thanks!"
			c.post.Text = m.Body
		}, false},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			candidate := manualGmailCandidate{
				thread: new(models.Thread),
				post:   new(models.Post),
			}
			*candidate.thread = *base.thread
			*candidate.post = *base.post
			msg := message
			if tc.edit != nil {
				tc.edit(&candidate, &msg)
			}
			if got := matchesManualGmailMessage(msg, candidate, memberID); got != tc.want {
				t.Errorf("matchesManualGmailMessage() = %t, want %t", got, tc.want)
			}
		})
	}
}
