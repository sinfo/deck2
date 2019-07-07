package models

import (
	"errors"
	"time"

	"github.com/globalsign/mgo/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
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

// CompanyParticipation stores a company's participation info.
type CompanyParticipation struct {

	// Participation's event (ID of Event).
	Event int `json:"event" bson:"event"`

	// Member in charge of this participation is a Member _id (see models.Member).
	Member primitive.ObjectID `json:"member" bson:"member"`

	// Participation's status.
	Status ParticipationStatus `json:"status" bson:"status"`

	// Participation's communications (array of IDs of Threads).
	Communications []primitive.ObjectID `json:"communications" bson:"communications"`

	// Participation's subscribers (array of IDs of Member).
	// All members in here will be notified on this participation's modification.
	Subscribers []primitive.ObjectID `json:"subscribers" bson:"subscribers"`

	// Participation's billing is a Billing _id (see models.Billing).
	Billing primitive.ObjectID `json:"billing" bson:"billing"`

	// Participation's package is a Package _id (see models.Package).
	Package primitive.ObjectID `json:"package" bson:"package"`

	Confirmed time.Time `json:"confirmed" bson:"confirmed"`

	// Is this company participating as a partner.
	Partner bool `json:"partner" bson:"partner"`

	// Some random notes about this participation.
	Notes string `json:"notes" bson:"notes"`
}

// CompanyBillingInfo of company
type CompanyBillingInfo struct {

	// Registered name of the company.
	Name string `json:"name" bson:"name"`

	// Registered address of the company.
	Address string `json:"address" bson:"address"`

	// Tax payer identification number of the company.
	TIN string `json:"tin" bson:"tin"`
}

// CompanyImages of company.
type CompanyImages struct {

	// Internal image URL (hosted somewhere).
	Internal string `json:"internal" bson:"internal"`

	// Public image URL (hosted somewhere).
	Public string `json:"public" bson:"public"`
}

// Company represents a company to be contacted by the team, that will hopefully participate
// on the event.
type Company struct {

	// Company's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name        string `json:"name" bson:"name"`
	Description string `json:"description" bson:"description"`

	// Company's images (public and internal).
	Images CompanyImages `json:"imgs" bson:"imgs"`

	Site string `json:"site" bson:"site"`

	// Company's contacts is an array of CompanyRep _id (see models.CompanyRep).
	Employers []primitive.ObjectID `json:"employers" bson:"employers"`

	BillingInfo    CompanyBillingInfo     `json:"billingInfo" bson:"billingInfo"`
	Participations []CompanyParticipation `json:"participations" bson:"participations"`
}

// ToBson converts a company to a bson format.
// Really usefull to create a company and adding it to the database without compromising the id.
func (c *Company) ToBson() bson.M {
	return bson.M{
		"name":        c.Name,
		"description": c.Description,
		"site":        c.Site,
	}
}

// AdvanceStatus advances status of participation.
// This follows a state machine well defined.
//   SUGGESTIONS
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
func (p *CompanyParticipation) AdvanceStatus(step int) error {
	switch p.Status {
	case Suggested:
		if step == 1 {
			p.Status = Selected
		} else if step == 2 {
			p.Status = OnHold
		} else {
			return errors.New("Invalid step")
		}

		break

	case Selected:
		if step == 1 {
			p.Status = Contacted
		} else {
			return errors.New("Invalid step")
		}

		break

	case OnHold:
		if step == 1 {
			p.Status = Selected
		} else {
			return errors.New("Invalid step")
		}

		break

	case Contacted:
		if step == 1 {
			p.Status = InConversations
		} else if step == 2 {
			p.Status = Rejected
		} else if step == 3 {
			p.Status = GivenUp
		} else {
			return errors.New("Invalid step")
		}

		break

	case InConversations:
		if step == 1 {
			p.Status = Accepted
		} else if step == 2 {
			p.Status = Rejected
		} else if step == 3 {
			p.Status = GivenUp
		} else {
			return errors.New("Invalid step")
		}

		break

	case Accepted:
		if step == 1 {
			p.Status = Announced
		} else {
			return errors.New("Invalid step")
		}

		break

	default:
		return errors.New("No steps available")
	}

	return nil
}
