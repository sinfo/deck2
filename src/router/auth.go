package router

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/google"
	"github.com/sinfo/deck2/src/mongodb"
)

type authResponse struct {
	JWT string `json:"access_token"`
}

const cookieName = "oauthstate"

func oauthGoogleLogin(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	url := urlQuery.Get("redirect")

	if len(url) == 0 {
		url = config.AuthRedirectionURL + "/login"
	}

	information := auth.Login(url)

	var expiration = time.Now().Add(365 * 24 * time.Hour)
	cookie := http.Cookie{Name: cookieName, Value: information.State, Expires: expiration}

	http.SetCookie(w, &cookie)
	http.Redirect(w, r, information.AuthURL, http.StatusTemporaryRedirect)
}

func oauthGoogleCallback(w http.ResponseWriter, r *http.Request) {

	// Read oauthState from Cookie
	oauthState, err := r.Cookie(cookieName)

	if err != nil {
		http.Error(w, "Invalid cookie on oauth google callback", http.StatusUnauthorized)
		return
	}

	if r.FormValue("state") != oauthState.Value {
		log.Println("invalid oauth google state")
		return
	}
	matches := UrlRegexCompiler.FindStringSubmatch(oauthState.Value)
	if len(matches) <= 1 {
		log.Println("Invalid RedirectUrl")
		return
	}

	log.Println(matches[1])

	var code = r.FormValue("code")

	data, err := google.GetUserData(code)
	if err != nil {
		log.Println(err.Error())
		return
	}

	//w.WriteHeader(http.StatusOK)

	var emailParts = strings.Split(data.Email, "@")
	if len(emailParts) != 2 {
		log.Println("error parsing user email")
		return
	}

	if (emailParts[1]) != "sinfo.org" {
		log.Println("not valid sinfo email")
		return
	}

	var sinfoid = emailParts[0]
	credentials, err := mongodb.Members.GetMemberAuthCredentials(sinfoid)
	if err != nil {
		log.Println("member not found, or without team")
		return
	}

	credentials.Token = data.Token

	token, err := auth.SignJWT(*credentials)
	if err != nil {
		log.Println("unable to create jwt" + err.Error())
		return
	}

	http.Redirect(w, r, fmt.Sprintf("%s/login/%s", matches[1], *token), http.StatusPermanentRedirect)
}
