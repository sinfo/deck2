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
	Post = models.Post{Member: primitive.NewObjectID(), Text: "some text"}
)

func TestGetPost(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	cpd := &mongodb.CreatePostData{
		Member: Post.Member,
		Text:   Post.Text,
	}

	createdPost, err := mongodb.Posts.CreatePost(*cpd)
	assert.NilError(t, err)

	var post models.Post

	res, err := executeRequest("GET", "/posts/"+createdPost.ID.Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&post)

	assert.Equal(t, post.ID, createdPost.ID)
}

func TestGetPostNotFound(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/posts/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}

func TestUpdatePost(t *testing.T) {
	ctx := context.Background()

	defer mongodb.Events.Collection.Drop(ctx)
	defer mongodb.Posts.Collection.Drop(ctx)

	if _, err := mongodb.Events.Collection.InsertOne(ctx, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	cpd := &mongodb.CreatePostData{
		Member: Post.Member,
		Text:   Post.Text,
	}

	createdPost, err := mongodb.Posts.CreatePost(*cpd)
	assert.NilError(t, err)

	newTeam, err := mongodb.Teams.CreateTeam(mongodb.CreateTeamData{Name: "TEAM1"})
	assert.NilError(t, err)

	var role = models.RoleAdmin

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

	var newText = "a different text"

	upd := &mongodb.UpdatePostData{
		Text: newText,
	}

	b, errMarshal := json.Marshal(upd)
	assert.NilError(t, errMarshal)

	var post models.Post

	config.Authentication = true
	res, err := executeAuthenticatedRequest("PUT", "/posts/"+createdPost.ID.Hex(), bytes.NewBuffer(b), *token)
	config.Authentication = false

	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusOK)

	json.NewDecoder(res.Body).Decode(&post)

	assert.Equal(t, post.ID, createdPost.ID)
	assert.Equal(t, post.Text, newText)
	assert.Equal(t, post.Updated.After(post.Posted), true)
}
