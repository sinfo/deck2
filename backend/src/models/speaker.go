package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type SpeakerParticipationRoom struct {

	// Small description of the booking.
	Type string `json:"type" bson:"type"`

	// Cost of the booking in cents (€).
	Cost int `json:"cost" bson:"cost"`

	// Additional information, like which hotel, its address, etc.
	Notes string `json:"notes" bson:"notes"`
}

type SpeakerParticipation struct {

	// Event is an _id of Event (see models.Event).
	Event int `json:"event" bson:"event"`

	// Member is an _id of Member (see models.Member).
	Member primitive.ObjectID `json:"member" bson:"member"`

	// Participation's status. See models.Company
	Status ParticipationStatus `json:"status" bson:"status"`

	// Communications is an array of _id of Communication (see models.Communication).
	Communications []primitive.ObjectID `json:"communications" bson:"communications"`

	// Subscribers is an array of _id of Member (see models.Member).
	Subscribers []primitive.ObjectID `json:"subscribers" bson:"subscribers"`

	// Feedback given by the speaker regarding the conference. This will be visible on
	// our website.
	Feedback string `json:"feedback" bson:"feedback"`

	// Flights is an array of _id of FlightInfo (see models.FlightInfo).
	Flights []primitive.ObjectID `json:"flights" bson:"flights"`

	// Hotel information regarding this speaker.
	Room SpeakerParticipationRoom `json:"room" bson:"room"`
}

type SpeakerImages struct {

	// Internal image, only visible by the team.
	Internal string `json:"internal" bson:"internal"`

	// Speaker photo. This is a URL pointing to the photo, stored somewhere. It will
	// be visible on our website.
	Speaker string `json:"speaker" bson:"speaker"`

	// Speaker's company photo. This is a URL pointing to the photo, stored somewhere. It will
	// be visible on our website.
	Company string `json:"company" bson:"company"`
}

type Speaker struct {

	// Speaker's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name string `json:"name" bson:"name"`

	// Contact is an _id of Contact (see models.Contact).
	Contact *primitive.ObjectID `json:"contact,omitempty" bson:"contact"`

	// Title of the speaker (CEO @ HugeCorportation, for example).
	Title string `json:"title" bson:"title"`

	// Bio of the speaker. Careful, this will be visible on our website!
	Bio string `json:"bio" bson:"bio"`

  // Company name
  CompanyName string `json:"companyName" bson:"companyName"`

	// This is only visible by the team. Praise and trash talk at will.
	Notes          string                 `json:"notes" bson:"notes"`
	Images         SpeakerImages          `json:"imgs" bson:"imgs"`
	Participations []SpeakerParticipation `json:"participations" bson:"participations"`
}

type SpeakerImagesPublic struct {

	// Speaker photo. This is a URL pointing to the photo, stored somewhere. It will
	// be visible on our website.
	Speaker string `json:"speaker" bson:"speaker"`

	// Speaker's company photo. This is a URL pointing to the photo, stored somewhere. It will
	// be visible on our website.
	Company string `json:"company,omitempty" bson:"company"`
}

type SpeakerParticipationPublic struct {

	// Event is an _id of Event (see models.Event).
	Event int `json:"event" bson:"event"`

	// Feedback given by the speaker regarding the conference. This will be visible on
	// our website.
	Feedback string `json:"feedback" bson:"feedback"`
}

// SpeakerPublic represents a speaker to be contacted by the team, that will hopefully participate
// on the event, and to be shown to everyone publicly.
type SpeakerPublic struct {
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Name string `json:"name" bson:"name"`

	// Title of the speaker (CEO @ HugeCorportation, for example).
	Title string `json:"title" bson:"title"`

	// Bio of the speaker. Careful, this will be visible on our website!
	Bio string `json:"bio" bson:"bio"`

  // Company name
  CompanyName string `json:"companyName,omitempty" bson:"companyName"`

	Images         SpeakerImagesPublic          `json:"imgs" bson:"imgs"`
	Participations []SpeakerParticipationPublic `json:"participation" bson:"participations"`
}
