package auth

import (
	"errors"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Claims struct {
	ID      primitive.ObjectID `json:"id"`
	SINFOID string             `json:"sinfoid"`
	Role    models.TeamRole    `json:"role"`
	Token   primitive.ObjectID `json:"token"`
	jwt.StandardClaims
}

var jwtSecret []byte

const jwtLifeTime = time.Duration(time.Hour * 24 * 7 * 2) // 2 weeks

func InitializeJWT() {
	jwtSecret = []byte(config.JWTSecret)
}

func SignJWT(credentials models.AuthorizationCredentials) (*string, error) {

	var expirationTime = time.Now().Add(jwtLifeTime)

	claims := &Claims{
		ID:      credentials.ID,
		SINFOID: credentials.SINFOID,
		Role:    credentials.Role,
		Token:   credentials.Token,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		return nil, err
	}

	return &tokenString, nil
}

func ParseJWT(tokenString string) (*models.AuthorizationCredentials, error) {

	var claims Claims

	token, err := jwt.ParseWithClaims(tokenString, &claims, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	if _, err := mongodb.Members.GetMember(claims.ID); err != nil {
		return nil, errors.New("invalid member on token")
	}

	result := models.AuthorizationCredentials{
		ID:      claims.ID,
		SINFOID: claims.SINFOID,
		Role:    claims.Role,
		Token:   claims.Token,
	}

	return &result, nil
}
