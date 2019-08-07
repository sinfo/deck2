package router

import (
	"encoding/json"
	"bytes"
	"net/http"
	"net/url"
	"testing"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"gotest.tools/assert"
)

var(
	Contact1		*models.Contact
	Contact1Phone = models.ContactPhone{
		Phone: "1",
		Valid:true,
	}
	Contact1Socials = models.ContactSocials{
		Facebook: "facebook",
		Skype: "skype",
		Github: "github",
		Twitter: "twitter",
		LinkedIn: "linkedin",
	}
	Contact1Mail = models.ContactMail{
		Mail: "2",
		Personal: true,
		Valid: true,
	}
	Contact1Data = mongodb.CreateContactData{
		Phones: append(make([]models.ContactPhone, 0), Contact1Phone),
		Socials: Contact1Socials,
		Mails: append(make([]models.ContactMail, 0), Contact1Mail),
	}
	Contact2		*models.Contact
	Contact2Phone = models.ContactPhone{
		Phone: "3",
		Valid:true,
	}
	Contact2Socials = models.ContactSocials{
		Facebook: "facebook2",
		Skype: "skype2",
		Github: "github2",
		Twitter: "twitter2",
		LinkedIn: "linkedin2",
	}
	Contact2Mail = models.ContactMail{
		Mail: "4",
		Personal: true,
		Valid: true,
	}
	Contact2Data = mongodb.CreateContactData{
		Phones: append(make([]models.ContactPhone, 0), Contact2Phone),
		Socials: Contact2Socials,
		Mails: append(make([]models.ContactMail, 0), Contact2Mail),
	}
)

func containsContact(l []models.Contact, c *models.Contact) bool{
	for _,s := range l{
		if s.ID == c.ID{
			return true
		}
	}
	return false
}

func TestGetContacts(t *testing.T){
	defer mongodb.Contacts.Collection.Drop(mongodb.Contacts.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	//Setup

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	assert.NilError(t, err)

	Member2, err := mongodb.Members.CreateMember(Member2Data)
	assert.NilError(t, err)

	Member1, err  = mongodb.Contacts.CreateContactMember(Member1.ID, Contact1Data)
	assert.NilError(t, err)

	Member2, err  = mongodb.Contacts.CreateContactMember(Member2.ID, Contact2Data)
	assert.NilError(t, err)

	Contact1, err = mongodb.Contacts.GetContact(Member1.Contact)
	assert.NilError(t, err)

	Contact2, err = mongodb.Contacts.GetContact(Member2.Contact)
	assert.NilError(t, err)

	//No query

	var contacts []models.Contact

	res, err := executeRequest("GET", "/contacts", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&contacts)

	assert.Equal(t, len(contacts), 2)
	assert.Equal(t, containsContact(contacts, Contact1), true)
	assert.Equal(t, containsContact(contacts, Contact2), true)

	//Phone on query

	var query1 = "?phone="+url.QueryEscape(Contact1.Phones[0].Phone)

	res, err = executeRequest("GET", "/contacts"+query1, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&contacts)

	assert.Equal(t, len(contacts), 1)
	assert.Equal(t, containsContact(contacts, Contact1), true)
	assert.Equal(t, containsContact(contacts, Contact2), false)

	//Mail on query

	var query2 = "?mail="+url.QueryEscape(Contact2.Mails[0].Mail)

	res, err = executeRequest("GET", "/contacts"+query2, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&contacts)

	assert.Equal(t, len(contacts), 1)
	assert.Equal(t, containsContact(contacts, Contact1), false)
	assert.Equal(t, containsContact(contacts, Contact2), true)

	// Both on query

	res, err = executeRequest("GET", "/contacts"+query1+query2, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&contacts)

	assert.Equal(t, len(contacts), 0)
	assert.Equal(t, containsContact(contacts, Contact1), false)
	assert.Equal(t, containsContact(contacts, Contact2), false)
}

func TestGetContact(t *testing.T){

	defer mongodb.Contacts.Collection.Drop(mongodb.Contacts.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	//Setup

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	assert.NilError(t, err)

	Member1, err  = mongodb.Contacts.CreateContactMember(Member1.ID, Contact1Data)
	assert.NilError(t, err)

	var contact models.Contact

	res, err := executeRequest("GET", "/contacts/"+Member1.Contact.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&contact)

	assert.Equal(t, contact.ID, Member1.Contact)
	assert.Equal(t, contact.Phones[0].Phone, Contact1Phone.Phone)
	assert.Equal(t, contact.Mails[0].Mail, Contact1Mail.Mail)

}

func TestGetContactBadId(t *testing.T){
	res, err := executeRequest("GET", "/contacts/wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdateContact(t *testing.T){
	defer mongodb.Contacts.Collection.Drop(mongodb.Contacts.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	//Setup

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	assert.NilError(t, err)

	Member1, err  = mongodb.Contacts.CreateContactMember(Member1.ID, Contact1Data)
	assert.NilError(t, err)

	var contact models.Contact

	b, errMarshal := json.Marshal(Contact2Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/contacts/"+Member1.Contact.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&contact)

	assert.Equal(t, contact.ID, Member1.Contact)
	assert.Equal(t, contact.Phones[0].Phone, Contact2Phone.Phone)

}