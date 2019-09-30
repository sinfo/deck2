package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
	"strings"
)

type ContactPhone struct {
	Phone string `json:"phone" bson:"phone"`
	Valid bool   `json:"valid" bson:"valid"`
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
	Valid    bool   `json:"valid" bson:"valid"`
}

// Contact stores contacts' information. It doesn't hold a name, because it's used on models.CompanyRep,
// models.Member and models.Speaker. All of them already hold a name.
type Contact struct {
	// Contact's ID (_id of mongodb).
	ID primitive.ObjectID `json:"id" bson:"_id"`

	Phones  []ContactPhone `json:"phones" bson:"phones"`
	Socials ContactSocials `json:"socials" bson:"socials"`
	Mails   []ContactMail  `json:"mails" bson:"mails"`
}

// HasPhone (phone) returns true if contact has a valid phone
// number that is a case insensitive partial match to `phone`
func (c *Contact) HasPhone(p string) bool {
	for _, s := range c.Phones {
		if strings.Contains(strings.ToLower(s.Phone), strings.ToLower(p)) && s.Valid {
			return true
		}
	}
	return false
}

// HasMail (mail) returns true if contact has a valid mail
// that is a case insensitive partial match to `mail`
func (c *Contact) HasMail(m string) bool {
	for _, s := range c.Mails {
		if strings.Contains(strings.ToLower(s.Mail), strings.ToLower(m)) && s.Valid {
			return true
		}
	}
	return false
}
