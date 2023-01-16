package router

import (
	"bytes"
	"context"
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/threads/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestAddCommentToThread(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
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
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
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

func TestUpdateThread(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Threads.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)
	defer mongodb.Members.Collection.Drop(ctx)
	defer mongodb.Meetings.Collection.Drop(ctx)
	defer mongodb.Teams.Collection.Drop(ctx)
	defer mongodb.Events.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	utmd := mongodb.CreateTeamMemberData{
		Member: newMember.ID,
		Role:   role,
	}

	newTeam, err = mongodb.Teams.AddTeamMember(newTeam.ID, utmd)
	assert.NilError(t, err)

	cmtd := mongodb.CreateMeetingData{
		Begin: &TimeBefore,
		End:   &TimeAfter,
		Place: &Place1,
	}

	oldMeeting, err := mongodb.Meetings.CreateMeeting(cmtd)
	assert.NilError(t, err)

	newMeeting, err := mongodb.Meetings.CreateMeeting(cmtd)
	assert.NilError(t, err)

	cpd := mongodb.CreatePostData{
		Member: newMember.ID,
		Text:   "Some text",
	}

	post, err := mongodb.Posts.CreatePost(cpd)
	assert.NilError(t, err)

	oldKind := models.ThreadKindTemplate
	newKind := models.ThreadKindFrom

	ctd := mongodb.CreateThreadData{
		Entry:   post.ID,
		Meeting: &oldMeeting.ID,
		Kind:    oldKind,
	}

	thread, err := mongodb.Threads.CreateThread(ctd)
	assert.NilError(t, err)

	credentials, err := mongodb.Members.GetMemberAuthCredentials(newMember.SINFOID)
	assert.NilError(t, err)

	token, err := auth.SignJWT(*credentials)
	assert.NilError(t, err)

	data := mongodb.UpdateThreadData{
		Meeting: &newMeeting.ID,
		Kind:    newKind,
	}

	b, errMarshal := json.Marshal(data)
	assert.NilError(t, errMarshal)

	config.Authentication = true
	res, err := executeAuthenticatedRequest("PUT", "/threads/"+thread.ID.Hex(), bytes.NewBuffer(b), *token)
	config.Authentication = false
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	var updatedThread models.Thread

	json.NewDecoder(res.Body).Decode(&updatedThread)

	assert.Equal(t, updatedThread.ID, thread.ID)
	assert.Equal(t, *updatedThread.Meeting, newMeeting.ID)
	assert.Equal(t, updatedThread.Kind, newKind)

	res, err = executeRequest("GET", "/meetings/"+oldMeeting.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)

}
