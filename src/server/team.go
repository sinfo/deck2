package server

import (
	"encoding/json"
	"net/http"
	//"net/url"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"


	"github.com/gorilla/mux"
)

func GetTeamsHandler(w http.ResponseWriter, r *http.Request) {

	query := bson.M{} //BuildQuery(r.URL.Query())

	teams, err := mongodb.Teams.GetTeams(query)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(teams)
}

func CreateTeamHandler(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ctd = &mongodb.CreateTeamData{}

	if err := ctd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newTeam, err := mongodb.Teams.CreateTeam(*ctd)

	if err != nil {
		http.Error(w, "Could not create team", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newTeam)
}

func GetTeamHandler(w http.ResponseWriter, r *http.Request) {
	params :=mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])
	
	team, err := mongodb.Teams.GetTeam(id)
	
	if err != nil {
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func DeleteTeamHandler(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])

	team, err := mongodb.Teams.DeleteTeam(id)

	if err != nil {
		http.Error(w, "Could not find team", http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(team)
}
