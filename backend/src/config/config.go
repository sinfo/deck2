package config

import (
	"fmt"
	"log"

	"github.com/spf13/viper"
)

var (
	Testing        bool = false
	Authentication bool = true
	Production     bool = false

	Host        string = "localhost"
	Port        string = "8080"
	CallBackURL string = "http://localhost:8080"

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
	ImageMaxSize  int64 = 10 << 10
	MinuteMaxSize int64 = 500 << 10

	// Where to send the authentication token after successeful authentication
	// We will be using deck website (https://deck.sinfo.org)
	AuthRedirectionURL string

	SinfoCalendarName string
)

const (
	keyPrefix string = "DECK2"

	keyHost string = "HOST"
	keyPort string = "PORT"

	keyDatabaseURI  string = "DB_URL"
	keyDatabaseName string = "DB_NAME"
	keyCallbackURL  string = "CALLBACK_URL"

	keyGoogleOAuthClientID     string = "GOOGLE_OAUTH_CLIENT_ID"
	keyGoogleOAuthClientSecret string = "GOOGLE_OAUTH_CLIENT_SECRET"

	keyJWTSecret string = "JWT_SECRET"

	keyDOPAT string = "DO_PAT"

	keySpacesName   string = "DO_SPACES_NAME"
	keySpacesSecret string = "DO_SPACES_SECRET"
	keySpacesKey    string = "DO_SPACES_KEY"

	keyAuthRedirectionURL string = "AUTH_REDIRECTION_URL"

	keySinfoCalendarName string = "SINFO_CALENDAR_NAME"
)

func set(variable *string, key string, mandatory bool) {
	if viper.IsSet(keyPrefix + "_" + key) {
		*variable = viper.GetString(keyPrefix + "_" + key)
	} else if viper.IsSet(key) {
		*variable = viper.GetString(key)
	} else if mandatory {
		log.Fatal(fmt.Sprintf("%s", key) + " not set")
	}
}

func InitializeConfig(filename string) {

	var file = true
	if filename != "" {
		viper.SetConfigName(filename)
		viper.AddConfigPath(".")
		if err := viper.ReadInConfig(); err != nil {
			file = false
		}

	}

	if filename == "" || !file {
		viper.SetEnvPrefix(keyPrefix)
		viper.AutomaticEnv()
	}

	set(&Host, keyHost, false)
	set(&Port, keyPort, false)

	set(&DatabaseURI, keyDatabaseURI, false)
	set(&DatabaseName, keyDatabaseName, false)
	set(&CallBackURL, keyCallbackURL, false)

	set(&GoogleOAuthClientID, keyGoogleOAuthClientID, true)
	set(&GoogleOAuthClientSecret, keyGoogleOAuthClientSecret, true)

	set(&JWTSecret, keyJWTSecret, true)

	set(&DOPAT, keyDOPAT, true)

	set(&SpacesName, keySpacesName, true)
	set(&SpacesKey, keySpacesKey, true)
	set(&SpacesSecret, keySpacesSecret, true)

	set(&AuthRedirectionURL, keyAuthRedirectionURL, true)

	// If you want to modify or test with the GoogleAPI in DevMode, you must set the env
	set(&SinfoCalendarName, keySinfoCalendarName, Production)
}

func SetTestingEnv() {
	Testing = true
	Authentication = false
	DatabaseName = "deck2_testing"
}
