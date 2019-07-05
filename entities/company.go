package entities

import (
	"time"

	"github.com/globalsign/mgo/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

/*
participations: [{
    partner: Boolean,
    notes: String,
  }],
*/

// Participation info of company
// swagger:model
type Participation struct {

	// participation's event (ID of Event)
	// required: true
	Event primitive.ObjectID `json:"event" bson:"event"`

	// member in charge of this participation (ID of Member)
	// required: true
	Member primitive.ObjectID `json:"member" bson:"member"`

	// participation's status
	// must be one of the following:
	//   - SUGGESTED
	//   - SELECTED
	//   - ON_HOLD
	//   - CONTACTED
	//   - IN_CONVERSATIONS
	//   - ACCEPTED
	//   - REJECTED
	//   - GIVEN_UP
	//   - ANNOUNCED
	// required: true
	Status string `json:"status" bson:"status"`

	// participation's communications (array of IDs of Threads)
	// required: true
	Communications []primitive.ObjectID `json:"communications" bson:"communications"`

	// participation's subscribers (array of IDs of Member)
	// all members in here will be notified on this participation's modification
	// required: true
	Subscribers []primitive.ObjectID `json:"subscribers" bson:"subscribers"`

	// participation's billing (ID of Billing)
	// required: true
	Billing primitive.ObjectID `json:"billing" bson:"billing"`

	// participation's package (ID of Package)
	// required: true
	Package primitive.ObjectID `json:"package" bson:"package"`

	// participation's confirmation date
	// required: true
	Confirmed time.Time `json:"confirmed" bson:"confirmed"`

	// is this company participating as a partner
	// required: true
	Partner bool `json:"partner" bson:"partner"`

	// some random notes about this participation
	// required: true
	Notes string `json:"notes" bson:"notes"`
}

// BillingInfo of company
// swagger:model
type BillingInfo struct {

	// registered name of the company
	// required: true
	// min length: 1
	Name string `json:"name" bson:"name"`

	// registered address of the company
	// required: true
	// min length: 1
	Address string `json:"address" bson:"address"`

	// tax payer identification number of the company
	// required: true
	// min length: 9
	// max length: 9
	TIN string `json:"tin" bson:"tin"`
}

// Images of company
// swagger:model
type Images struct {
	// internal image URL (hosted somewhere)
	// required: true
	// min length: 1
	Internal string `json:"internal" bson:"internal"`

	// public image URL (hosted somewhere)
	// required: true
	// min length: 1
	Public string `json:"public" bson:"public"`
}

// Company represents a company to be stored in the database and parsed from http requests
// swagger:model
type Company struct {

	// company's ID (_id of mongodb)
	// required: true
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// company's name
	// required: true
	// min length: 1
	Name string `json:"name" bson:"name"`

	// company's description
	// required: true
	Description string `json:"description" bson:"description"`

	// company's images (public and internal)
	// required: true
	Images `json:"imgs" bson:"imgs"`

	// company's site
	// required: true
	Site string `json:"site" bson:"site"`

	// company's contacts
	// required: true
	Employers []primitive.ObjectID `json:"employers" bson:"employers"`

	// company's billing info
	// required: true
	BillingInfo `json:"billingInfo" bson:"billingInfo"`

	// company's participations
	// required: true
	Participations []Participation `json:"participations" bson:"participations"`
}

// ToBson converts a company to a bson format
// Really usefull to create a company and adding it to the database without compromising the id
func (c *Company) ToBson() bson.M {
	return bson.M{
		"name":        c.Name,
		"description": c.Description,
		"site":        c.Site,
	}
}
