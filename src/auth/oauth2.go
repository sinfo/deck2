package auth

import (
	"crypto/rand"
	"encoding/base64"

	"github.com/sinfo/deck2/src/config"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

var OauthConfig *oauth2.Config

func InitializeOAuth2() error {

	OauthConfig = &oauth2.Config{
		RedirectURL:  "http://localhost:8080/auth/callback",
		ClientID:     config.GoogleOAuthClientID,
		ClientSecret: config.GoogleOAuthClientSecret,
		Scopes:       []string{"https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/calendar"},
		Endpoint:     google.Endpoint,
	}

	return nil
}

func generateStateOauthCookie() string {

	b := make([]byte, 16)
	rand.Read(b)

	state := base64.URLEncoding.EncodeToString(b)

	return state
}

type LoginInformation struct {
	State   string
	AuthURL string
}

func Login() LoginInformation {

	// Create oauthState cookie for CSRF protection
	var state = generateStateOauthCookie()

	hostDomainOption := oauth2.SetAuthURLParam("hd", "sinfo.org")
	authURL := OauthConfig.AuthCodeURL(state, hostDomainOption)

	var info = LoginInformation{
		State:   state,
		AuthURL: authURL,
	}

	return info
}
