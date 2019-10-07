package mongodb

import (
	"context"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/oauth2"
)

type TokensType struct {
	Collection *mongo.Collection
	Context    context.Context
}

func (t *TokensType) GetToken(id primitive.ObjectID) (*models.Token, error) {

	var token models.Token

	if err := t.Collection.FindOne(t.Context, bson.M{
		"_id": id,
	}).Decode(&token); err != nil {
		return nil, err
	}

	return &token, nil
}

func (t *TokensType) CreateToken(token *oauth2.Token) (*models.Token, error) {
	insertResult, err := t.Collection.InsertOne(t.Context, bson.M{
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
