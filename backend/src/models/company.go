package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
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

	// Participation's package is a Package _id (see models.Package).
	Package *primitive.ObjectID `json:"package" bson:"package"`

	// Participation's billing is a billing _id (see models.Billing).
	Billing *primitive.ObjectID `json:"billing" bson:"billing"`

	Confirmed time.Time `json:"confirmed" bson:"confirmed"`

	// Is this company participating as a partner.
	Partner bool `json:"partner" bson:"partner"`

	// Some random notes about this participation.
	Notes string `json:"notes" bson:"notes"`

  // Stand details
  StandDetails StandDetails `json:"standDetails,omitempty" bson:"standDetails,omitempty"`

  // Stand and days at the venue
  Stands []Stand `json:"stands,omitempty" bson:"stands,omitempty"`

}

type Stand struct {
  // Stand identifier
  StandID string  `json:"standId" bson:"standId"`

  // Day at the venue
  Date *time.Time `json:"date,omitempty" bson:"date,omitempty"`
}

type StandDetails struct {
  // Number of chairs required by the company
  Chairs int `json:"chairs" bson:"chairs"`

  // Require front table
  Table bool `json:"table" bson:"table"`

  // Require lettering
  Lettering bool `json:"lettering" bson:"lettering"`
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
	Images CompanyImages `json:"imgs,omitempty" bson:"imgs,omitempty"`

	Site string `json:"site" bson:"site"`

	// Company's contacts is an array of CompanyRep _id (see models.CompanyRep).
	Employers []primitive.ObjectID `json:"employers,omitempty" bson:"employers,omitempty"`

	BillingInfo    CompanyBillingInfo     `json:"billingInfo,omitempty" bson:"billingInfo,omitempty"`
	Participations []CompanyParticipation `json:"participations" bson:"participations"`

	// Contact is an _id of Contact (see models.Contact).
	Contact primitive.ObjectID `json:"contact" bson:"contact"`
}

// CompanyParticipationPublic stores a company's participation info to be shown to everyone publicly.
type CompanyParticipationPublic struct {

	// Participation's event (ID of Event).
	Event int `json:"event"`

	// Is this company participating as a partner.
	Partner bool `json:"partner"`

	// Participation's package is a Package _id (see models.Package).
	Package PackagePublic `json:"package,omitempty"`

  // Stand details
  StandDetails StandDetails `json:"standDetails,omitempty"`

  // Days at the venue
  Stands []Stand `json:"stands,omitempty"`
}

// CompanyPublic represents a company to be contacted by the team, that will hopefully participate
// on the event, and to be shown to everyone publicly.
type CompanyPublic struct {
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name string `json:"name"`

	Description string `json:"description"`

	// Company's image (public).
	Image string `json:"img,omitempty"`

	Site string `json:"site,omitempty"`

	Participations []CompanyParticipationPublic `json:"participation,omitempty"`
}
