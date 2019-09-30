package router

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"testing"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	Thread = models.Thread{Entry: primitive.NewObjectID(), Meeting: nil, Kind: models.ThreadKindTo}
)

func TestGetThread(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	ctd := &mongodb.CreateThreadData{
		Entry:   Thread.Entry,
		Meeting: Thread.Meeting,
		Kind:    Thread.Kind,
	}

	createdThread, err := mongodb.Threads.CreateThread(*ctd)
	assert.NilError(t, err)

	var thread models.Thread

	res, err := executeRequest("GET", "/threads/"+createdThread.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&thread)

	assert.Equal(t, thread.ID, createdThread.ID)
}

func TestGetThreadNotFound(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/threads/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddCommentToThread(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	ctd := mongodb.CreateThreadData{
		Entry:   Thread.Entry,
		Meeting: Thread.Meeting,
		Kind:    Thread.Kind,
	}

	thread, err := mongodb.Threads.CreateThread(ctd)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	var text = "some comment text"
	acttd := &addCommentToThreadData{
		Text: &text,
	}

	var updatedThread models.Thread

	b, errMarshal := json.Marshal(acttd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/threads/"+thread.ID.Hex()+"/comments", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedThread)

	assert.Equal(t, updatedThread.ID, thread.ID)
	assert.Equal(t, len(updatedThread.Comments), 1)
	postID := updatedThread.Comments[0]

	post, err := mongodb.Posts.GetPost(postID)
	assert.NilError(t, err)

	assert.Equal(t, post.Text, text)
}

func TestAddCommentToThreadInvalidPayload(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	ctd := mongodb.CreateThreadData{
		Entry:   Thread.Entry,
		Meeting: Thread.Meeting,
		Kind:    Thread.Kind,
	}

	thread, err := mongodb.Threads.CreateThread(ctd)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	var text = "some comment text"
	type InvalidPayload struct {
		NotText *string
	}

	acttd := &InvalidPayload{
		NotText: &text,
	}

	b, errMarshal := json.Marshal(acttd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/threads/"+thread.ID.Hex()+"/comments", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusBadRequest)
}

func TestAddCommentToThreadInvalidThreadID(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	var text = "some comment text"
	acttd := &addCommentToThreadData{
		Text: &text,
	}

	b, errMarshal := json.Marshal(acttd)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("POST", "/threads/"+primitive.NewObjectID().Hex()+"/comments", bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusExpectationFailed)
}

func TestRemoveCommentFromThread(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	ctd := mongodb.CreateThreadData{
		Entry:   Thread.Entry,
		Meeting: Thread.Meeting,
		Kind:    Thread.Kind,
	}

	thread, err := mongodb.Threads.CreateThread(ctd)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	var text = "some comment text"
	cpd := mongodb.CreatePostData{
		Member: credentials.ID,
		Text:   text,
	}

	post, err := mongodb.Posts.CreatePost(cpd)
	assert.NilError(t, err)

	updatedThread, err := mongodb.Threads.AddCommentToThread(thread.ID, post.ID)
	assert.NilError(t, err)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("DELETE", "/threads/"+thread.ID.Hex()+"/comments/"+post.ID.Hex(), nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&updatedThread)

	assert.Equal(t, updatedThread.ID, thread.ID)
	assert.Equal(t, len(updatedThread.Comments), 0)
}

func TestRemoveCommentFromThreadInvalidThread(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	var text = "some comment text"
	cpd := mongodb.CreatePostData{
		Member: credentials.ID,
		Text:   text,
	}

	post, err := mongodb.Posts.CreatePost(cpd)
	assert.NilError(t, err)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("DELETE", "/threads/"+primitive.NewObjectID().Hex()+"/comments/"+post.ID.Hex(), nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

	_, err = mongodb.Posts.GetPost(post.ID)
	assert.NilError(t, err)
}

func TestRemoveCommentFromThreadInvalidPost(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Threads.Collection.Drop(mongodb.Threads.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)
	defer mongodb.Teams.Collection.Drop(mongodb.Teams.Context)
	defer mongodb.Members.Collection.Drop(mongodb.Members.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	ctd := mongodb.CreateThreadData{
		Entry:   Thread.Entry,
		Meeting: Thread.Meeting,
		Kind:    Thread.Kind,
	}

	thread, err := mongodb.Threads.CreateThread(ctd)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleMember

	cmd := mongodb.CreateMemberData{
		Name: "Member",

		Istid:   "ist123456",
		SINFOID: "sinfoID",
	}

	newMember, err := mongodb.Members.CreateMember(cmd)
	assert.NilError(t, err)

	utmd := mongodb.UpdateTeamMemberData{
		Member: &newMember.ID,
		Role:   &role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("DELETE", "/threads/"+thread.ID.Hex()+"/comments/"+primitive.NewObjectID().Hex(), nil, *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
