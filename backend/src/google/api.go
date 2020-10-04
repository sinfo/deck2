package google

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"golang.org/x/oauth2"
	"google.golang.org/api/calendar/v3"
)

const oauthGoogleURLAPI = "https://www.googleapis.com/oauth2/v2/userinfo?access_token="

type UserData struct {
	ID       string             `json:"id"`
	Email    string             `json:"email"`
	Verified bool               `json:"verified_email"`
	Picture  string             `json:"picture"`
	HD       string             `json:"hd"`
	Token    primitive.ObjectID `json:"token,omitempty"`
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

	newToken, err := mongodb.Tokens.CreateToken(token)
	if err != nil {
		return nil, err
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

	result.Token = newToken.ID

	return &result, nil
}

func GetUserDataWithToken(token string) (*UserData, error) {

	response, err := http.Get(oauthGoogleURLAPI + token)
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

// GetCalendarService returns a service able to make request to the google calendar api"
// TODO: Integerate calendarService in GetUserData!!!!!
func GetCalendarService(code string) (*calendar.Service, error) {
	token, err := auth.OauthConfig.Exchange(context.Background(), code)
	if err != nil {
		return nil, fmt.Errorf("code exchange wrong: %s", err.Error())
	}

	client := oauth2.NewClient(context.Background(), oauth2.StaticTokenSource(token))

	calendarService, err := calendar.New(client)
	if err != nil {
		return nil, fmt.Errorf("couldn't retrieve calendar service: %s", err.Error())
	}

	return calendarService, nil
}
