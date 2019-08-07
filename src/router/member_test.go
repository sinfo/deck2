package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"testing"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"gotest.tools/assert"
)

var (
	Member1Data = mongodb.CreateMemberData{
		Name:    "Member1",
		Image:   "Image1.png",
		Istid:   "ist123456",
		SinfoID: "john.doe",
	}
	Member2Data = mongodb.CreateMemberData{
		Name:    "Member2",
		Image:   "Image2.png",
		Istid:   "ist654321",
		SinfoID: "mary.jane",
	}
	Member1 *models.Member
	Member2 *models.Member
)

func containsMember(members []models.Member, member *models.Member) bool {
	for _, s := range members {
		if s.ID == member.ID && s.Name == member.Name {
			return true
		}
	}

	return false
}

func TestGetMembers(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	Member2, err := mongodb.Members.CreateMember(Member2Data)
	if err != nil {
		log.Fatal(err)
	}

	var members []models.Member

	res, err := executeRequest("GET", "/members", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 2)
	assert.Equal(t, containsMember(members, Member1), true)
	assert.Equal(t, containsMember(members, Member2), true)

}

func TestGetMembersName(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	Member2, err := mongodb.Members.CreateMember(Member2Data)
	if err != nil {
		log.Fatal(err)
	}

	var members []models.Member
	var query = "?name=" + url.QueryEscape("member")

	res, err := executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 2)
	assert.Equal(t, containsMember(members, Member1), true)
	assert.Equal(t, containsMember(members, Member2), true)

	query = "?name=" + url.QueryEscape("1")

	res, err = executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 1)
	assert.Equal(t, containsMember(members, Member1), true)
	assert.Equal(t, containsMember(members, Member2), false)

	query = "?name=" + url.QueryEscape("a")

	res, err = executeRequest("GET", "/members"+query, nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&members)

	assert.Equal(t, len(members), 0)
	assert.Equal(t, containsMember(members, Member1), false)
	assert.Equal(t, containsMember(members, Member2), false)

}

func TestGetMember(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/members/"+Member1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member models.Member

	json.NewDecoder(res.Body).Decode(&member)

	assert.Equal(t, Member1.Name, member.Name)
	assert.Equal(t, Member1.ID, member.ID)
}

func TestGetMemberBadID(t *testing.T) {
	res, err := executeRequest("GET", "/members/wrong", nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestCreateMember(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	b, errMarshal := json.Marshal(Member1Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member1, member2 models.Member

	json.NewDecoder(res.Body).Decode(&member1)

	assert.Equal(t, member1.Name, Member1Data.Name)

	res, err = executeRequest("GET", "/members/"+member1.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&member2)

	assert.Equal(t, member2.Name, member1.Name)
	assert.Equal(t, member2.ID, member1.ID)
}

func TestCreateMemberBadPayload(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	cmdName := mongodb.CreateMemberData{
		Name:  "",
		Image: "Image.png",
		Istid: "ist111111",
	}

	b, errMarshal := json.Marshal(cmdName)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdImage := mongodb.CreateMemberData{
		Name:  "Name",
		Image: "",
		Istid: "ist111111",
	}

	b, errMarshal = json.Marshal(cmdImage)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstid0 := mongodb.CreateMemberData{
		Name:  "Name",
		Image: "Image.png",
		Istid: "",
	}

	b, errMarshal = json.Marshal(cmdIstid0)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstidIst := mongodb.CreateMemberData{
		Name:  "Name",
		Image: "Image.png",
		Istid: "123456",
	}

	b, errMarshal = json.Marshal(cmdIstidIst)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("POST", "/members", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateMember(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	b, errMarshal := json.Marshal(Member2Data)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member models.Member

	json.NewDecoder(res.Body).Decode(&member)

	assert.Equal(t, Member2Data.Name, member.Name)
	assert.Equal(t, Member1.ID, member.ID)
}

func TestUpdateMemberBadPayload(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	cmdName := mongodb.CreateMemberData{
		Name:  "",
		Image: "Image.png",
		Istid: "ist111111",
	}

	b, errMarshal := json.Marshal(cmdName)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdImage := mongodb.CreateMemberData{
		Name:  "Name",
		Image: "",
		Istid: "ist111111",
	}

	b, errMarshal = json.Marshal(cmdImage)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstid0 := mongodb.CreateMemberData{
		Name:  "Name",
		Image: "Image.png",
		Istid: "",
	}

	b, errMarshal = json.Marshal(cmdIstid0)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)

	cmdIstidIst := mongodb.CreateMemberData{
		Name:  "Name",
		Image: "Image.png",
		Istid: "123456",
	}

	b, errMarshal = json.Marshal(cmdIstidIst)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("PUT", "/members/"+Member1.ID.Hex(), bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestUpdateMemberContact(t *testing.T) {
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	updateData := mongodb.UpdateMemberContactData{
		Contact: primitive.NewObjectID(),
	}

	b, errMarshal := json.Marshal(updateData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/members/"+Member1.ID.Hex()+"/contact", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member models.Member

	json.NewDecoder(res.Body).Decode(&member)

	assert.Equal(t, updateData.Contact, member.Contact)
	assert.Equal(t, Member1.ID, member.ID)
}

func TestUpdateMemberContactBadID(t *testing.T) {

	updateData := mongodb.UpdateMemberContactData{
		Contact: primitive.NewObjectID(),
	}

	b, errMarshal := json.Marshal(updateData)
	assert.NilError(t, errMarshal)

	res, err := executeRequest("PUT", "/members/wrong/contact", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestDeleteMemberNotification(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	var notifID = primitive.NewObjectID()
	notifarr := make([]primitive.ObjectID, 0)
	notifarr = append(notifarr, notifID)

	dmnd := mongodb.DeleteMemberNotificationData{
		Notification: notifID,
	}

	b, errMarshal := json.Marshal(dmnd)
	assert.NilError(t, errMarshal)

	Member2, err := mongodb.Members.UpdateMemberNotification(Member1.ID, notifarr)
	assert.NilError(t, err)
	assert.Equal(t, Member1.ID, Member2.ID)
	assert.Equal(t, len(Member2.Notifications), 1)
	assert.Equal(t, Member2.Notifications[0], notifID)

	res, err := executeRequest("DELETE", "/members/"+Member1.ID.Hex()+"/notification", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var member models.Member

	json.NewDecoder(res.Body).Decode(&member)

	assert.Equal(t, Member2.ID, member.ID)
	assert.Equal(t, len(member.Notifications), 0)

}

func TestDeleteMemberNotificationWrongIDS(t *testing.T) {

	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	Member1, err := mongodb.Members.CreateMember(Member1Data)
	if err != nil {
		log.Fatal(err)
	}

	var notifID = primitive.NewObjectID()
	notifarr := make([]primitive.ObjectID, 0)
	notifarr = append(notifarr, notifID)

	dmnd := mongodb.DeleteMemberNotificationData{
		Notification: primitive.NewObjectID(),
	}

	b, errMarshal := json.Marshal(dmnd)
	assert.NilError(t, errMarshal)

	Member2, err := mongodb.Members.UpdateMemberNotification(Member1.ID, notifarr)
	assert.NilError(t, err)
	assert.Equal(t, Member1.ID, Member2.ID)
	assert.Equal(t, len(Member2.Notifications), 1)
	assert.Equal(t, Member2.Notifications[0], notifID)

	res, err := executeRequest("DELETE", "/members/"+Member1.ID.Hex()+"/notification", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	dmnd = mongodb.DeleteMemberNotificationData{
		Notification: notifID,
	}

	b, errMarshal = json.Marshal(dmnd)
	assert.NilError(t, errMarshal)

	res, err = executeRequest("DELETE", "/members/wrong"+"/notification/", bytes.NewBuffer(b))
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
