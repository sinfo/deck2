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

	Confirmed *time.Time `json:"confirmed,omitempty" bson:"confirmed,omitempty"`

	// Is this company participating as a partner.
	Partner bool `json:"partner" bson:"partner"`

	// Some random notes about this participation.
	Notes string `json:"notes" bson:"notes"`

	// GmailThreadIds is an array of Gmail thread IDs linked to this participation.
	// These are used to sync communications with Gmail.
	GmailThreadIds []string `json:"gmailThreadIds,omitempty" bson:"gmailThreadIds,omitempty"`

	// Stand details
	StandDetails StandDetails `json:"standDetails,omitempty" bson:"standDetails,omitempty"`

	// Stand and days at the venue
	Stands []Stand `json:"stands,omitempty" bson:"stands,omitempty"`

	// Tasks tracks the company's task pipeline progress.
	Tasks CompanyTasks `json:"tasks" bson:"tasks"`
}

type Stand struct {
	// Stand identifier
	StandID string `json:"standId" bson:"standId"`

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

	LinkedIn string `json:"linkedin,omitempty" bson:"linkedin,omitempty"`

	// Company's contacts is an array of CompanyRep _id (see models.CompanyRep).
	Employers []primitive.ObjectID `json:"employers,omitempty" bson:"employers,omitempty"`

	BillingInfo    CompanyBillingInfo     `json:"billingInfo,omitempty" bson:"billingInfo,omitempty"`
	Participations []CompanyParticipation `json:"participations" bson:"participations"`

	// Contact is an _id of Contact (see models.Contact).
	Contact primitive.ObjectID `json:"contact" bson:"contact"`

	// Relationships with other companies (acquisitions, mergers, rebrands).
	// Stored on both sides: the related company holds the inverse relationship.
	Relationships []CompanyRelationship `json:"relationships,omitempty" bson:"relationships,omitempty"`
}

// CompanyRelationshipType describes how a company relates to another one.
type CompanyRelationshipType string

const (
	// SubsidiaryOf means this company is owned by the related company.
	SubsidiaryOf CompanyRelationshipType = "SUBSIDIARY_OF"
	// ParentOf means this company owns the related company.
	ParentOf CompanyRelationshipType = "PARENT_OF"
	// MergedInto means this company no longer exists separately and is now part of the related company.
	MergedInto CompanyRelationshipType = "MERGED_INTO"
	// Absorbed means the related company was merged into this company.
	Absorbed CompanyRelationshipType = "ABSORBED"
	// RebrandedTo means this company is now known as the related company.
	RebrandedTo CompanyRelationshipType = "REBRANDED_TO"
	// RebrandedFrom means this company was previously known as the related company.
	RebrandedFrom CompanyRelationshipType = "REBRANDED_FROM"
)

var companyRelationshipInverses = map[CompanyRelationshipType]CompanyRelationshipType{
	SubsidiaryOf:  ParentOf,
	ParentOf:      SubsidiaryOf,
	MergedInto:    Absorbed,
	Absorbed:      MergedInto,
	RebrandedTo:   RebrandedFrom,
	RebrandedFrom: RebrandedTo,
}

// IsValid checks if the relationship type is a known one.
func (t CompanyRelationshipType) IsValid() bool {
	_, ok := companyRelationshipInverses[t]
	return ok
}

// Inverse returns the relationship type as seen from the related company.
func (t CompanyRelationshipType) Inverse() CompanyRelationshipType {
	return companyRelationshipInverses[t]
}

// PointsUp is true when the relationship goes from the owned/old company
// to the owning/new one (SUBSIDIARY_OF, MERGED_INTO, REBRANDED_TO).
func (t CompanyRelationshipType) PointsUp() bool {
	return t == SubsidiaryOf || t == MergedInto || t == RebrandedTo
}

// CompanyRelationship links a company to another one.
type CompanyRelationship struct {
	Type CompanyRelationshipType `json:"type" bson:"type"`

	// Company is the related company's _id (see models.Company).
	Company primitive.ObjectID `json:"company" bson:"company"`

	// When the acquisition, merger or rebrand happened.
	Since *time.Time `json:"since,omitempty" bson:"since,omitempty"`

	Notes string `json:"notes,omitempty" bson:"notes,omitempty"`
}

// RelatedCompany is a CompanyRelationship resolved with the related company's name and image.
type RelatedCompany struct {
	Type CompanyRelationshipType `json:"type"`

	// Company is the related company's _id (see models.Company).
	Company primitive.ObjectID `json:"company"`

	Name string `json:"name"`

	// Related company's image (internal, or public as fallback).
	Image string `json:"img,omitempty"`

	Since *time.Time `json:"since,omitempty"`

	Notes string `json:"notes,omitempty"`
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

	// Company's image (public).
	Image string `json:"img,omitempty"`

	Site string `json:"site,omitempty"`

	Participations []CompanyParticipationPublic `json:"participation,omitempty"`
}
