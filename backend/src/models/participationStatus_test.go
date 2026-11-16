package models

import "testing"

func TestNextCommunicationStatus(t *testing.T) {
	tests := []struct {
		name string
		current ParticipationStatus
		outgoing bool
		incoming bool
		want ParticipationStatus
	}{
		{"selected empty", Selected, false, false, Selected},
		{"selected outgoing", Selected, true, false, Contacted},
		{"selected incoming only", Selected, false, true, Selected},
		{"selected conversation", Selected, true, true, InConversations},
		{"contacted no reply", Contacted, true, false, Contacted},
		{"contacted reply", Contacted, false, true, InConversations},
		{"contacted both", Contacted, true, true, InConversations},
		{"conversation preserved", InConversations, true, false, InConversations},
		{"hold preserved", OnHold, true, true, OnHold},
		{"given up preserved", GivenUp, true, true, GivenUp},
		{"rejected preserved", Rejected, true, true, Rejected},
		{"accepted preserved", Accepted, true, true, Accepted},
		{"announced preserved", Announced, true, true, Announced},
		{"suggested preserved", Suggested, true, true, Suggested},
		{"not selected preserved", NotSelected, true, true, NotSelected},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := NextCommunicationStatus(tt.current, tt.outgoing, tt.incoming); got != tt.want {
				t.Errorf("got %q, want %q", got, tt.want)
			}
		})
	}
}
