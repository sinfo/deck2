package auth

import (
	"errors"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/sinfo/deck2/src/models"
	"github.com/spf13/viper"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Claims struct {
	ID      primitive.ObjectID `json:"id"`
	SINFOID string             `json:"sinfoid"`
	Role    models.TeamRole    `json:"role"`
	jwt.StandardClaims
}

var jwtKey []byte

const jwtLifeTime = time.Duration(time.Hour * 24 * 7 * 2) // 2 weeks

func InitializeJWT() error {
	if !viper.IsSet("JWT_KEY") {
		return errors.New("JWT_KEY not set")
	}

	jwtKey = []byte(viper.GetString("JWT_KEY"))

	return nil
}

func SignJWT(credentials models.AuthorizationCredentials) (*string, error) {

	var expirationTime = time.Now().Add(jwtLifeTime)

	claims := &Claims{
		ID:      credentials.ID,
		SINFOID: credentials.SINFOID,
		Role:    credentials.Role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		return nil, err
	}

	return &tokenString, nil
}

func ParseJWT(tokenString string) (*models.AuthorizationCredentials, error) {

	var claims Claims

	token, err := jwt.ParseWithClaims(tokenString, &claims, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	result := models.AuthorizationCredentials{
		ID:      claims.ID,
		SINFOID: claims.SINFOID,
		Role:    claims.Role,
	}

	return &result, nil
}
