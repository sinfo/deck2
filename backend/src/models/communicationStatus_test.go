package models

import "testing"

// Test automatic progression without modifying existing manual-state tests.
func TestNextCommunicationStatus(t *testing.T) {
	cases := []struct {
		current  ParticipationStatus
		outgoing bool
		incoming bool
		want     ParticipationStatus
	}{
		{Selected, false, false, Selected},
		{Selected, true, false, Contacted},
		{Selected, false, true, Selected},
		{Selected, true, true, InConversations},
		{Contacted, true, false, Contacted},
		{Contacted, false, true, InConversations},
		{Contacted, true, true, InConversations},
		{InConversations, true, false, InConversations},
		{OnHold, true, true, OnHold},
		{GivenUp, true, true, GivenUp},
		{Rejected, true, true, Rejected},
		{Accepted, true, true, Accepted},
		{Announced, true, true, Announced},
		{Suggested, true, true, Suggested},
		{NotSelected, true, true, NotSelected},
	}
	for _, c := range cases {
		if got := NextCommunicationStatus(c.current, c.outgoing, c.incoming); got != c.want {
			t.Errorf("status %q, outgoing %t, incoming %t: got %q, want %q",
				c.current, c.outgoing, c.incoming, got, c.want)
		}
	}
}
