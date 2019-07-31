package server

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
)

func getTeams(w http.ResponseWriter, r *http.Request) {

	query := bson.M{}

	teams, err := mongodb.Teams.GetTeams(query)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(teams)
}

func createTeam(w http.ResponseWriter, r *http.Request) {

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
