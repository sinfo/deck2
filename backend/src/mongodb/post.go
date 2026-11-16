package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// PostsType contains database information on posts
type PostsType struct {
	Collection *mongo.Collection
}

//CreatePostData holds data needed to create a post
type CreatePostData struct {
	Member primitive.ObjectID
	Text   string
}

// CreatePost creates a new post and saves it to the database
func (p *PostsType) CreatePost(data CreatePostData) (*models.Post, error) {
	ctx = context.Background()

	query := bson.M{
		"member": data.Member,
		"text":   data.Text,
		"posted": time.Now().UTC(),
	}

	insertResult, err := p.Collection.InsertOne(ctx, query)

	if err != nil {
		return nil, err
	}

	newPost, err := p.GetPost(insertResult.InsertedID.(primitive.ObjectID))

	if err != nil {
		log.Println("Error finding created post", err)
		return nil, err
	}

	return newPost, nil
}

// GetPost gets a post by its ID.
func (p *PostsType) GetPost(postID primitive.ObjectID) (*models.Post, error) {
	ctx = context.Background()
	var post models.Post

	err := p.Collection.FindOne(ctx, bson.M{"_id": postID}).Decode(&post)
	if err != nil {
		return nil, err
	}

	return &post, nil
}

// GetPostsByIDs reads the posts for a single participation in one query.
func (p *PostsType) GetPostsByIDs(ids []primitive.ObjectID) (map[primitive.ObjectID]*models.Post, error) {
	result := make(map[primitive.ObjectID]*models.Post, len(ids))
	if len(ids) == 0 {
		return result, nil
	}

	ctx := context.Background()
	cursor, err := p.Collection.Find(ctx, bson.M{"_id": bson.M{"$in": ids}})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var post models.Post
		if err := cursor.Decode(&post); err != nil {
			return nil, err
		}
		result[post.ID] = &post
	}
	return result, cursor.Err()
}

// DeletePost deletes a post by its ID.
func (p *PostsType) DeletePost(postID primitive.ObjectID) (*models.Post, error) {
	ctx = context.Background()

	var post models.Post

	err := p.Collection.FindOneAndDelete(ctx, bson.M{"_id": postID}).Decode(&post)
	if err != nil {
		return nil, err
	}

	return &post, nil
}

//UpdatePostData contains data needed to update a post
type UpdatePostData struct {
	Text string `json:"text"`
}

// ParseBody fills the CreateSessionData from a body
func (upd *UpdatePostData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(upd); err != nil {
		return err
	}

	if len(upd.Text) == 0 {
		return errors.New("invalid text")
	}

	return nil
}

// UpdatePost updates a post by its ID
func (p *PostsType) UpdatePost(postID primitive.ObjectID, data UpdatePostData) (*models.Post, error) {
	ctx = context.Background()

	var post models.Post

	var updateQuery = bson.M{
		"$set": bson.M{
			"text":    data.Text,
			"updated": time.Now().UTC(),
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := p.Collection.FindOneAndUpdate(ctx, bson.M{"_id": postID}, updateQuery, optionsQuery).Decode(&post); err != nil {
		return nil, err
	}

	return &post, nil

}
