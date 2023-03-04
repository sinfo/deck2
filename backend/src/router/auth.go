package router

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/google"
	"github.com/sinfo/deck2/src/mongodb"
)

type AuthResponse struct {
	DeckToken string `json:"deck_token" bson:"deck_token"`
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
		http.Error(w, "Invalid cookie on oauth google callback: " + err.Error(), http.StatusUnauthorized)
		return
	}

	if r.FormValue("state") != oauthState.Value {
		log.Println("invalid oauth google state")
		return
	}
	matches := URLRegexCompiler.FindStringSubmatch(oauthState.Value)
	if len(matches) <= 1 {
		log.Println("Invalid RedirectUrl")
		return
	}

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

	token, err := auth.SignJWT(*credentials)
	if err != nil {
		log.Println("unable to create jwt" + err.Error())
		return
	}

	http.Redirect(w, r, fmt.Sprintf("%s/%s", matches[1], *token), http.StatusPermanentRedirect)
}

type authRequest struct {
	AccessToken string `json:"access_token"`
}

func generateJwt(w http.ResponseWriter, r *http.Request) {

	var token authRequest

	err := json.NewDecoder(r.Body).Decode(&token)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	data, err := google.GetUserDataWithToken(token.AccessToken)
	if err != nil {
		log.Println(err.Error())
		return
	}

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
		log.Println("member " + sinfoid + "not found, or without team")
		return
	}

	decktoken, err := auth.SignJWT(*credentials)
	if err != nil {
		log.Println("unable to create jwt" + err.Error())
		return
	}

	var authResponse = &AuthResponse{
		DeckToken: *decktoken,
	}

	json.NewEncoder(w).Encode(authResponse)
}

func verifyToken(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	tokenString := params["token"]

	credentials, err := auth.ParseJWT(tokenString)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte("NOK"))
		return
	}

	member, err := mongodb.Members.GetMemberAuthCredentials(credentials.SINFOID)
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte("NOK"))
		return
	}

	if member.Role != credentials.Role || member.ID != credentials.ID {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte("NOK"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
