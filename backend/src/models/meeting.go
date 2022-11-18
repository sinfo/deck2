package models

import (
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type MeetingKind string
type MeetingParticipantKind string

const (
	EventMeeting   MeetingKind = "EVENT"
	TeamMeeting    MeetingKind = "TEAM"
	CompanyMeeting MeetingKind = "COMPANY"
)

const (
	MemberParticipant     MeetingParticipantKind = "MEMBER"
	CompanyRepParticipant MeetingParticipantKind = "COMPANYREP"
)

func (mk *MeetingKind) Parse(kind string) error {

	var newMeetingKind MeetingKind

	switch kind {

	case string(EventMeeting):
		newMeetingKind = EventMeeting
		break

	case string(TeamMeeting):
		newMeetingKind = TeamMeeting
		break

	case string(CompanyMeeting):
		newMeetingKind = CompanyMeeting
		break

	default:
		return errors.New("invalid kind")

	}

	*mk = newMeetingKind
	return nil
}

func (mk *MeetingParticipantKind) Parse(participantKind string) error {

	var newMeetingParticipantKind MeetingParticipantKind

	switch participantKind {

	case string(MemberParticipant):
		newMeetingParticipantKind = MemberParticipant
		break

	case string(CompanyRepParticipant):
		newMeetingParticipantKind = CompanyRepParticipant
		break

	default:
		return errors.New("invalid type of participant")

	}

	*mk = newMeetingParticipantKind
	return nil
}

type MeetingParticipants struct {

	// Members is an array of _id of Member (see models.Member).
	Members []primitive.ObjectID `json:"members" bson:"members"`

	// CompanyReps is an array of _id of CompanyRep (see models.CompanyRep).
	CompanyReps []primitive.ObjectID `json:"companyReps" bson:"companyReps"`
}

// Meeting stores informations abouts meetings with the SINFO team,
// or meetings scheduled with companies.
type Meeting struct {

	// Meeting's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	// The title of the meeting
	Title string `json:"title" bson:"title"`

	// Type of the meeting
	Kind MeetingKind `json:"kind" bson:"kind"`

	Begin time.Time `json:"begin" bson:"begin"`
	End   time.Time `json:"end" bson:"end"`

	// Place where the meeting is being held.
	Place string `json:"place" bson:"place"`

	// A written record of the meeting. This is typically a URL to where the
	// actual document is being stored.
	// "Ata" in portuguese.
	Minute string `json:"minute" bson:"minute"`

	// Communications is an array of _id of Communication (see models.Communication).
	Communications []primitive.ObjectID `json:"communications" bson:"communications"`

	Participants MeetingParticipants `json:"participants" bson:"participants"`
}
