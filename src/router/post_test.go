package router

import (
	"encoding/json"
	"log"
	"net/http"
	"testing"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"gotest.tools/assert"
)

var (
	Post = models.Post{Member: primitive.NewObjectID(), Text: "some text"}
)

func TestGetPost(t *testing.T) {

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)
	defer mongodb.Posts.Collection.Drop(mongodb.Posts.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
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

	defer mongodb.Events.Collection.Drop(mongodb.Events.Context)

	if _, err := mongodb.Events.Collection.InsertOne(mongodb.Events.Context, bson.M{"_id": Event1.ID, "name": Event1.Name}); err != nil {
		log.Fatal(err)
	}

	res, err := executeRequest("GET", "/posts/"+primitive.NewObjectID().Hex(), nil)
	assert.NilError(t, err)
	assert.Equal(t, res.Code, http.StatusNotFound)
}
