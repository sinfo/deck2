package mongodb

import (
	"context"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/oauth2"
)

//TokensType contains database information on tokens
type TokensType struct {
	Collection *mongo.Collection
}

//GetToken gets a token based on id
func (t *TokensType) GetToken(id primitive.ObjectID) (*models.Token, error) {

	ctx := context.Background()
	var token models.Token

	if err := t.Collection.FindOne(ctx, bson.M{
		"_id": id,
	}).Decode(&token); err != nil {
		return nil, err
	}

	return &token, nil
}

//CreateToken creates a token
func (t *TokensType) CreateToken(token *oauth2.Token) (*models.Token, error) {
	ctx := context.Background()
	insertResult, err := t.Collection.InsertOne(ctx, bson.M{
		"expiry":  token.Expiry,
		"refresh": token.RefreshToken,
		"access":  token.AccessToken,
	})

	if err != nil {
		return nil, err
	}

	newToken, err := t.GetToken(insertResult.InsertedID.(primitive.ObjectID))
	if err != nil {
		return nil, err
	}

	return newToken, nil
}
