package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type ContactPhone struct {
	Phone string `json:"phone" bson:"phone"`
	Valid bool   `json:"valid" bson:"valid"`
}

type ContactSocials struct {
	Facebook string `json:"facebook" bson:"facebook"`
	Skype    string `json:"skype" bson:"skype"`
	Github   string `json:"github" bson:"github"`
	Twitter  string `json:"twitter" bson:"twitter"`
	LinkedIn string `json:"linkedin" bson:"linkedin"`
}

type ContactMail struct {
	Mail     string `json:"mail" bson:"mail"`
	Personal bool   `json:"personal" bson:"personal"`
	Valid    bool   `json:"valid" bson:"valid"`
}

// Contact stores contacts' information. It doesn't hold a name, because it's used on models.CompanyRep,
// models.Member and models.Speaker. All of them already hold a name.
type Contact struct {
	ID      primitive.ObjectID `json:"id" bson:"_id"`
	Phones  []ContactPhone     `json:"phones" bson:"phones"`
	Socials ContactSocials     `json:"socials" bson:"socials"`
	Mails   []ContactMail      `json:"mails" bson:"mails"`
}
