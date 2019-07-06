package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type SpeakerParticipationRoom struct {
	Type  string
	Costs int
	Notes string
}

type SpeakerParticipationGuests struct {
	Name    string
	Flights primitive.ObjectID
}

type SpeakerParticipations struct {
	Event          primitive.ObjectID
	Member         primitive.ObjectID
	Status         string
	Communications []primitive.ObjectID
	Subscribers    []primitive.ObjectID
	Feedback       string
	Flights        primitive.ObjectID
	Guests         SpeakerParticipationGuests
	Room           SpeakerParticipationRoom
}

type SpeakerImages struct {
	Internal string
	Speaker  string
	Company  string
}

type Speaker struct {
	ID             primitive.ObjectID `json:"id" bson:"_id"`
	Name           string
	Contact        primitive.ObjectID
	Title          string
	Bio            string
	Notes          string
	Images         SpeakerImages
	Participations []SpeakerParticipations
}
