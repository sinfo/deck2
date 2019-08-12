package router

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/google"
	"github.com/sinfo/deck2/src/mongodb"
)

type authResponse struct {
	JWT string `json:"access_token"`
}

const cookieName = "oauthstate"

func oauthGoogleLogin(w http.ResponseWriter, r *http.Request) {

	information := auth.Login()

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
		http.Error(w, "Invalid oauth google state", http.StatusUnauthorized)
		return
	}

	var code = r.FormValue("code")

	data, err := google.GetUserData(code)
	if err != nil {
		log.Println(err.Error())
		http.Error(w, "error getting user information from google", http.StatusUnauthorized)
		return
	}

	w.WriteHeader(http.StatusOK)

	var emailParts = strings.Split(data.Email, "@")
	if len(emailParts) != 2 {
		http.Error(w, "error parsing user email", http.StatusUnauthorized)
		return
	}

	if (emailParts[1]) != "sinfo.org" {
		http.Error(w, "not valid sinfo email", http.StatusUnauthorized)
		return
	}

	var sinfoid = emailParts[0]
	credentials, err := mongodb.Members.GetMemberAuthCredentials(sinfoid)
	if err != nil {
		http.Error(w, "member not found, or without team", http.StatusUnauthorized)
		return
	}

	token, err := auth.SignJWT(*credentials)
	if err != nil {
		http.Error(w, "unable to create jwt", http.StatusUnauthorized)
		return
	}

	var response = authResponse{JWT: *token}

	json.NewEncoder(w).Encode(response)
}
