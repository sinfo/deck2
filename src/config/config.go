package config

import (
	"fmt"
	"log"

	"github.com/spf13/viper"
)

var (
	Testing bool = false

	Host string = "localhost"
	Port string = "8080"

	DatabaseURI  string = "mongodb://localhost:27017"
	DatabaseName string = "deck2"

	GoogleOAuthClientID     string
	GoogleOAuthClientSecret string

	JWTSecret string
)

const (
	keyPrefix string = "DECK2"

	keyHost string = "HOST"
	keyPort string = "PORT"

	keyDatabaseURI  string = "DB_URL"
	keyDatabaseName string = "DB_NAME"

	keyGoogleOAuthClientID     string = "GOOGLE_OAUTH_CLIENT_ID"
	keyGoogleOAuthClientSecret string = "GOOGLE_OAUTH_CLIENT_SECRET"

	keyJWTSecret string = "JWT_SECRET"
)

func InitializeConfig() {
	viper.SetEnvPrefix(keyPrefix)
	viper.AutomaticEnv()

	if viper.IsSet(keyHost) {
		Host = viper.GetString(keyHost)
	}

	if viper.IsSet(keyPort) {
		Port = viper.GetString(keyPort)
	}

	if viper.IsSet(keyDatabaseURI) {
		DatabaseURI = viper.GetString(keyDatabaseURI)
	}

	if viper.IsSet(keyDatabaseName) {
		DatabaseName = viper.GetString(keyDatabaseName)
	}

	if viper.IsSet(keyGoogleOAuthClientID) {
		GoogleOAuthClientID = viper.GetString(keyGoogleOAuthClientID)
	} else {
		log.Fatal(fmt.Sprintf("%s_%s", keyPrefix, keyGoogleOAuthClientID) + " not set")
	}

	if viper.IsSet(keyGoogleOAuthClientSecret) {
		GoogleOAuthClientSecret = viper.GetString(keyGoogleOAuthClientSecret)
	} else {
		log.Fatal(fmt.Sprintf("%s_%s", keyPrefix, keyGoogleOAuthClientSecret), " not set")
	}

	if viper.IsSet(keyJWTSecret) {
		JWTSecret = viper.GetString(keyJWTSecret)
	} else {
		log.Fatal(fmt.Sprintf("%s_%s", keyPrefix, keyJWTSecret), " not set")
	}
}

func SetTestingEnv() {
	Testing = true
	DatabaseName = "deck2_testing"
}
