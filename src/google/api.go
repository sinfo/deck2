package google

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/sinfo/deck2/src/auth"
)

const oauthGoogleURLAPI = "https://www.googleapis.com/oauth2/v2/userinfo?access_token="

type UserData struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	Verified bool   `json:"verified_email"`
	Picture  string `json:"picture"`
	HD       string `json:"hd"`
}

// GetUserData uses code to get token and user info from Google.
func GetUserData(code string) (*UserData, error) {

	token, err := auth.OauthConfig.Exchange(context.Background(), code)
	if err != nil {
		return nil, fmt.Errorf("code exchange wrong: %s", err.Error())
	}

	response, err := http.Get(oauthGoogleURLAPI + token.AccessToken)
	if err != nil {
		return nil, fmt.Errorf("failed getting user info: %s", err.Error())
	}

	defer response.Body.Close()

	contents, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return nil, fmt.Errorf("failed read response: %s", err.Error())
	}

	var result UserData

	err = json.Unmarshal(contents, &result)
	if err != nil {
		return nil, fmt.Errorf("failed to parse response from google for user data: %s", err.Error())
	}

	return &result, nil
}
