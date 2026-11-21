package models

import "testing"

func TestCommunicationStatus(t *testing.T) {
	tests := []struct {
		name                           string
		current                        ParticipationStatus
		hasOutgoing, hasManualIncoming bool
		want                           ParticipationStatus
	}{
		{"selected without communication", Selected, false, false, Selected},
		{"outgoing marks selected as contacted", Selected, true, false, Contacted},
		{"manual incoming cannot skip selected", Selected, false, true, Selected},
		{"selected advances only one step", Selected, true, true, Contacted},
		{"gmail incoming does not advance contacted", Contacted, true, false, Contacted},
		{"manual incoming advances contacted", Contacted, true, true, InConversations},
		{"manual incoming advances manually set contacted", Contacted, false, true, InConversations},
		{"contacted survives deleting outgoing communication", Contacted, false, false, Contacted},
		{"in conversations survives gmail resync", InConversations, true, false, InConversations},
		{"in conversations survives deleting all communications", InConversations, false, false, InConversations},
		{"in conversations survives deleting outgoing communication", InConversations, false, true, InConversations},
		{"in conversations remains with all communications", InConversations, true, true, InConversations},
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
			if got := CommunicationStatus(tc.current, tc.hasOutgoing, tc.hasManualIncoming); got != tc.want {
				t.Errorf("CommunicationStatus(%q, %t, %t) = %q, want %q", tc.current, tc.hasOutgoing, tc.hasManualIncoming, got, tc.want)
			}
		})
	}
}
