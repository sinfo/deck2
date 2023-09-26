package models

import "time"

type Requirement struct {
	Title        string    `json:"title"`
	Name         string    `json:"name"`
	Type         string    `json:"type"`
	StringValue  string    `json:"stringVal"`
	IntegerValue int       `json:"intVal"`
	BoolValue    bool      `json:"boolVal"`
	DateValue    time.Time `json:"dateVal"`
}
