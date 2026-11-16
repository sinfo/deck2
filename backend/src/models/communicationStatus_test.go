package models

import "testing"

func TestCommunicationStatus(t *testing.T) {
	tests := []struct {
		name                     string
		current                  ParticipationStatus
		hasOutgoing, hasIncoming bool
		want                     ParticipationStatus
	}{
		{"selected unchanged without messages", Selected, false, false, Selected},
		{"outgoing message marks contacted", Selected, true, false, Contacted},
		{"incoming alone does not mark contacted", Selected, false, true, Selected},
		{"both messages mark in conversations", Selected, true, true, InConversations},
		{"contacted stays without incoming", Contacted, true, false, Contacted},
		{"incoming marks in conversations", Contacted, true, true, InConversations},
		{"removing last outgoing reverts to selected", Contacted, false, false, Selected},
		{"contacted without outgoing reverts to selected", Contacted, false, true, Selected},
		{"removing last reply reverts to contacted", InConversations, true, false, Contacted},
		{"removing last outgoing reverts to selected", InConversations, false, true, Selected},
		{"removing all messages reverts to selected", InConversations, false, false, Selected},
		{"in conversations remains when both exist", InConversations, true, true, InConversations},
		{"on hold preserved", OnHold, false, false, OnHold},
		{"given up preserved", GivenUp, false, false, GivenUp},
		{"rejected preserved", Rejected, false, false, Rejected},
		{"accepted preserved", Accepted, false, false, Accepted},
		{"announced preserved", Announced, false, false, Announced},
		{"suggested preserved", Suggested, true, true, Suggested},
		{"not selected preserved", NotSelected, true, true, NotSelected},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := CommunicationStatus(tc.current, tc.hasOutgoing, tc.hasIncoming); got != tc.want {
				t.Errorf("CommunicationStatus(%q, %t, %t) = %q, want %q", tc.current, tc.hasOutgoing, tc.hasIncoming, got, tc.want)
			}
		})
	}
}
