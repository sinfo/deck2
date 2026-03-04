package models

import (
	"strings"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type ContactPhone struct {
	Phone string `json:"phone" bson:"phone"`
}

type ContactSocials struct {
	Facebook string `json:"facebook,omitempty" bson:"facebook"`
	Skype    string `json:"skype,omitempty" bson:"skype"`
	Github   string `json:"github,omitempty" bson:"github"`
	Twitter  string `json:"twitter,omitempty" bson:"twitter"`
	LinkedIn string `json:"linkedin,omitempty" bson:"linkedin"`
}

type ContactMail struct {
	Mail     string `json:"mail" bson:"mail"`
	Personal bool   `json:"personal" bson:"personal"`
}

type Gender string
const (
	GenMale   Gender = "MALE"
	GenFemale Gender = "FEMALE"
	GenOther  Gender = "OTHER"
)

type Language string
const (
	LangEnglish Language = "ENGLISH"
	LangPortuguese Language = "PORTUGUESE"
)

// Contact stores contacts' information. It doesn't hold a name, because it's used on models.CompanyRep,
// models.Member and models.Speaker. All of them already hold a name.
type Contact struct {
	// Contact's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Gender Gender `json:"gender" bson:"gender"`
	Language Language `json:"language" bson:"language"`
	Phones  []ContactPhone `json:"phones" bson:"phones"`
	Socials ContactSocials `json:"socials" bson:"socials"`
	Mails   []ContactMail  `json:"mails" bson:"mails"`
}

// HasPhone (phone) returns true if contact has a phone
// number that is a case insensitive partial match to `phone`
func (c *Contact) HasPhone(p string) bool {
	for _, s := range c.Phones {
		if strings.Contains(strings.ToLower(s.Phone), strings.ToLower(p)) {
			return true
		}
	}
	return false
}

// HasMail (mail) returns true if contact has a valid mail
// that is a case insensitive partial match to `mail`
func (c *Contact) HasMail(m string) bool {
	for _, s := range c.Mails {
		if strings.Contains(strings.ToLower(s.Mail), strings.ToLower(m)) {
			return true
		}
	}
	return false
}
