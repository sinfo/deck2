package config

import (
	"fmt"
	"log"

	"github.com/spf13/viper"
)

var (
	Testing        bool = false
	Authentication bool = true

	Host string = "localhost"
	Port string = "8080"

	DatabaseURI  string = "mongodb://localhost:27017"
	DatabaseName string = "deck2"

	GoogleOAuthClientID     string
	GoogleOAuthClientSecret string

	JWTSecret string

	// Digitalocean Personal Access Token
	DOPAT string

	SpacesName   string
	SpacesSecret string
	SpacesKey    string

	// Max size of the images to be uploaded by deck2 (Companies public and private images,
	// speakers public and private images, etc)
	// 10 KB
	ImageMaxSize int64 = 10 << 10
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

	keyDOPAT string = "DO_PAT"

	keySpacesName   string = "DO_SPACES_NAME"
	keySpacesSecret string = "DO_SPACES_SECRET"
	keySpacesKey    string = "DO_SPACES_KEY"
)

func set(variable *string, key string, mandatory bool) {
	if viper.IsSet(key) {
		*variable = viper.GetString(key)
	} else if mandatory {
		log.Fatal(fmt.Sprintf("%s_%s", keyPrefix, key) + " not set")
	}
}

func InitializeConfig() {
	viper.SetEnvPrefix(keyPrefix)
	viper.AutomaticEnv()

	set(&Host, keyHost, false)
	set(&Port, keyPort, false)

	set(&DatabaseURI, keyDatabaseURI, false)
	set(&DatabaseName, keyDatabaseName, false)

	set(&GoogleOAuthClientID, keyGoogleOAuthClientID, true)
	set(&GoogleOAuthClientSecret, keyGoogleOAuthClientSecret, true)

	set(&JWTSecret, keyJWTSecret, true)

	set(&DOPAT, keyDOPAT, true)

	set(&SpacesName, keySpacesName, true)
	set(&SpacesKey, keySpacesKey, true)
	set(&SpacesSecret, keySpacesSecret, true)
}

func SetTestingEnv() {
	Testing = true
	Authentication = false
	DatabaseName = "deck2_testing"
}
