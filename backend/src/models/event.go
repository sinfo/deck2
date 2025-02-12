package models

import (
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type EventPackages struct {

	// Template is a Package _id (see models.Package).
	Template primitive.ObjectID `json:"template" bson:"template"`

	PublicName string `json:"public_name" bson:"public_name"`

	Available bool `json:"available" bson:"available"`
}

// Event info.
type Event struct {

	// Event's ID (_id of mongodb).
	// Example: SINFO 26 has id=26.
	ID int `json:"id" bson:"_id"`

	Name  string     `json:"name" bson:"name"`
	Begin *time.Time `json:"begin,omitempty" bson:"begin,omitempty"`
	End   *time.Time `json:"end,omitempty" bson:"end,omitempty"`

	// Event days' themes.
	// Each index of the array corresponds to a week day during the event.
	// Example: index 1 corresponds to monday, index 2 to tuesday, etc).
	// The themes can be "Software Engineer", "Security", "Gaming", etc.
	Themes []string `json:"themes" bson:"themes"`

	Packages []EventPackages      `json:"packages" bson:"packages"`
	Items    []primitive.ObjectID `json:"items" bson:"items"`

	// Meetings is an array of Meeting _id (see models.Meeting).
	Meetings []primitive.ObjectID `json:"meetings" bson:"meetings"`

	// Sessions is an array of Session _id (see models.Session).
	Sessions []primitive.ObjectID `json:"sessions" bson:"sessions"`

	// Teams is an array of Team_id (see models.Team).
	Teams []primitive.ObjectID `json:"teams" bson:"teams"`

	// Calendar is a link to the event's calendar.
	CalendarUrl string `json:"calendarUrl" bson:"calendarUrl"`
}

// DurationInDays returns the duration of the event in days.
func (e Event) DurationInDays() (int, error) {

	var result = 1

	if e.Begin == nil || e.End == nil {
		return -1, errors.New("event's dates not set'")
	}

	var start = *e.Begin
	var end = *e.End

	for start.Day() != end.Day() {
		result++
		start = start.Add(time.Hour * 24)
	}

	return result, nil
}

// EventPublic info.
type EventPublic struct {

	// Event's ID (_id of mongodb).
	// Example: SINFO 26 has id=26.
	ID int `json:"id" bson:"_id"`

	Name  string     `json:"name" bson:"name"`
	Begin *time.Time `json:"begin,omitempty" bson:"begin,omitempty"`
	End   *time.Time `json:"end,omitempty" bson:"end,omitempty"`

	// Event days' themes.
	// Each index of the array corresponds to a week day during the event.
	// Example: index 1 corresponds to monday, index 2 to tuesday, etc).
	// The themes can be "Software Engineer", "Security", "Gaming", etc.
	Themes []string `json:"themes" bson:"themes"`

	CalendarUrl string `json:"calendarUrl" bson:"calendarUrl"`
}

// DurationInDays returns the duration of the event in days.
func (e EventPublic) DurationInDays() (int, error) {
	var result = 1

	if e.Begin == nil || e.End == nil {
		return -1, errors.New("event's dates not set'")
	}

	var start = *e.Begin
	var end = *e.End

	for start.Day() != end.Day() {
		result++
		start = start.Add(time.Hour * 24)
	}

	return result, nil
}
