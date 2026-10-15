package models

import (
	"testing"

	"gotest.tools/assert"
)

func TestParticipationStatusTransitions(t *testing.T) {
	testCases := []struct {
		status ParticipationStatus
		steps  []ValidStep
	}{
		{status: Suggested, steps: []ValidStep{{Step: 1, Next: NotSelected}, {Step: 2, Next: OnHold}}},
		{status: Selected, steps: []ValidStep{{Step: 1, Next: Contacted}}},
		{status: NotSelected, steps: []ValidStep{{Step: 1, Next: Selected}}},
		{status: OnHold, steps: []ValidStep{{Step: 1, Next: Selected}, {Step: 2, Next: InConversations}}},
		{status: Contacted, steps: []ValidStep{{Step: 1, Next: InConversations}, {Step: 2, Next: Rejected}, {Step: 3, Next: GivenUp}}},
		{status: InConversations, steps: []ValidStep{{Step: 1, Next: Accepted}, {Step: 2, Next: OnHold}}},
		{status: Accepted, steps: []ValidStep{{Step: 1, Next: Announced}}},
	}

	for _, tc := range testCases {
		status := tc.status
		assert.DeepEqual(t, status.ValidSteps(), tc.steps)

		for _, step := range tc.steps {
			status = tc.status
			assert.NilError(t, status.Next(step.Step))
			assert.Equal(t, status, step.Next)
		}

		status = tc.status
		assert.ErrorContains(t, status.Next(0), "Invalid step")
	}
}
