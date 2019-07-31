package models

import "errors"

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
