package models

import (
	"errors"
)

type ParticipationStatus string

const (
	Suggested       ParticipationStatus = "SUGGESTED"
	Selected        ParticipationStatus = "SELECTED"
	OnHold          ParticipationStatus = "ON_HOLD"
	Contacted       ParticipationStatus = "CONTACTED"
	InConversations ParticipationStatus = "IN_CONVERSATIONS"
	Accepted        ParticipationStatus = "ACCEPTED"
	Rejected        ParticipationStatus = "REJECTED"
	GivenUp         ParticipationStatus = "GIVEN_UP"
	Announced       ParticipationStatus = "ANNOUNCED"
)

// Next advances status of participation.
// This follows a state machine well defined.
//   SUGGESTED
//      1 => SELECTED
//      2 => ON_HOLD
//   SELECTED
//      1 => CONTACTED
//   ON_HOLD
//      1 => SELECTED
//   CONTACTED
//      1 => IN_CONVERSATIONS
//      2 => REJECTED
//      3 => GIVEN_UP
//   IN_CONVERSATIONS
//      1 => ACCEPTED
//      2 => REJECTED
//      3 => GIVEN_UP
//   ACCEPTED
//      1 => ANNOUNCED
func (s *ParticipationStatus) Next(step int) error {
	switch *s {
	case Suggested:
		if step == 1 {
			*s = Selected
		} else if step == 2 {
			*s = OnHold
		} else {
			return errors.New("Invalid step")
		}

		break

	case Selected:
		if step == 1 {
			*s = Contacted
		} else {
			return errors.New("Invalid step")
		}

		break

	case OnHold:
		if step == 1 {
			*s = Selected
		} else {
			return errors.New("Invalid step")
		}

		break

	case Contacted:
		if step == 1 {
			*s = InConversations
		} else if step == 2 {
			*s = Rejected
		} else if step == 3 {
			*s = GivenUp
		} else {
			return errors.New("Invalid step")
		}

		break

	case InConversations:
		if step == 1 {
			*s = Accepted
		} else if step == 2 {
			*s = Rejected
		} else if step == 3 {
			*s = GivenUp
		} else {
			return errors.New("Invalid step")
		}

		break

	case Accepted:
		if step == 1 {
			*s = Announced
		} else {
			return errors.New("Invalid step")
		}

		break

	default:
		return errors.New("No steps available")
	}

	return nil
}

// ValidStep is the structure used on the function ValidSteps to display the valid steps to be taken given a certain status
type ValidStep struct {

	// A valid step
	Step int `json:"step"`

	// The status set after the above step is taken
	Next ParticipationStatus `json:"next"`
}

// ValidSteps displays the valid steps given a certain status
func (s *ParticipationStatus) ValidSteps() []ValidStep {

	switch *s {
	case Suggested:
		return []ValidStep{
			ValidStep{Step: 1, Next: Selected},
			ValidStep{Step: 2, Next: OnHold},
		}

	case Selected:
		return []ValidStep{
			ValidStep{Step: 1, Next: Contacted},
		}

	case OnHold:
		return []ValidStep{
			ValidStep{Step: 1, Next: Selected},
		}

	case Contacted:
		return []ValidStep{
			ValidStep{Step: 1, Next: InConversations},
			ValidStep{Step: 2, Next: Rejected},
			ValidStep{Step: 3, Next: GivenUp},
		}

	case InConversations:
		return []ValidStep{
			ValidStep{Step: 1, Next: Accepted},
			ValidStep{Step: 2, Next: Rejected},
			ValidStep{Step: 3, Next: GivenUp},
		}

	case Accepted:
		return []ValidStep{
			ValidStep{Step: 1, Next: Announced},
		}

	default:
		return []ValidStep{}
	}
}

func (s *ParticipationStatus) Parse(status string) error {

	if s == nil {
		return errors.New("allocation needed before parsing")
	}

	var newStatus ParticipationStatus

	switch status {

	case string(Suggested):
		newStatus = Suggested
		break

	case string(Selected):
		newStatus = Selected
		break

	case string(OnHold):
		newStatus = OnHold
		break

	case string(Contacted):
		newStatus = Contacted
		break

	case string(InConversations):
		newStatus = InConversations
		break

	case string(Accepted):
		newStatus = Accepted
		break

	case string(Rejected):
		newStatus = Rejected
		break

	case string(GivenUp):
		newStatus = GivenUp
		break

	case string(Announced):
		newStatus = Announced
		break

	default:
		return errors.New("Invalid status")

	}

	*s = newStatus

	return nil
}
