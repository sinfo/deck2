package router

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)


// GetTeamsHandler is the handler for the GET /teams request.
// Has a query with event={EventID}, member={MemberID}, name={Name}.
// EventID is an int, memberID is a hexed primitive.ObjectID and name is a string.
func getTeams(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetTeamsOptions{}

	name := urlQuery.Get("name")
	member := urlQuery.Get("member")
	event := urlQuery.Get("event")

	if len(name) >0 {
		options.Name = &name
	}

	if len(member) >0 {
		memberID, err :=primitive.ObjectIDFromHex(member)
		if err != nil {
			http.Error(w, "Invalid member ID format", http.StatusBadRequest)
			return
		}
		options.Member = &memberID
	}

	if len(event) > 0 {
		eventID, err :=strconv.Atoi(event)
		if err !=nil {
			http.Error(w, "Invalid event ID format", http.StatusBadRequest)
			return
		}
		options.Event = &eventID
	}

	teams, err := mongodb.Teams.GetTeams(options)

	if err != nil {
		http.Error(w, "Unable to make query do database", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(teams)
}


// CreateTeamHandler is the handler for the POST /teams request.
// Takes in a payload with {name: string}
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


// GetTeamHandler is the handler for the GET /teams/{id} request.
// id is a hexed primitive.ObjectID
func getTeam(w http.ResponseWriter, r *http.Request) {
	params :=mux.Vars(r)
	id,_ := primitive.ObjectIDFromHex(params["id"])
	
	team, err := mongodb.Teams.GetTeam(id)

	if err != nil {
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

// DeleteTeamHandler is the handler for the DELETE /teams/{id} request.
// id is a hexed primitive.ObjectID
func deleteTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	team, err := mongodb.Teams.DeleteTeam(id)

	if err != nil {
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}


func updateTeam(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ctd = &mongodb.CreateTeamData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := ctd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedTeam, err := mongodb.Teams.UpdateTeam(id, *ctd)

	if err != nil {
		http.Error(w, "Could not update team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(updatedTeam)
}

func addTeamMember(w http.ResponseWriter, r *http.Request){
	defer r.Body.Close()

	var utmd = &mongodb.UpdateTeamMemberData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := utmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	team, err := mongodb.Teams.AddTeamMember(id, *utmd)
	if err != nil{
		if err.Error() == "Duplicate member"{
			http.Error(w, err.Error(), http.StatusBadRequest)	
		}else{
			http.Error(w, "Team or member not found", http.StatusNotFound)
		}
		return
	}

	json.NewEncoder(w).Encode(team)
}

func updateTeamMemberRole(w http.ResponseWriter, r *http.Request){
	defer r.Body.Close()

	var utmd = &mongodb.UpdateTeamMemberData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := utmd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	team, err := mongodb.Teams.UpdateTeamMemberRole(id, *utmd)
	if err != nil{
		http.Error(w, "Team or member not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}

func deleteTeamMember(w http.ResponseWriter, r *http.Request){
	defer r.Body.Close()

	var dtmd = &mongodb.DeleteTeamMemberData{}
	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if err := json.NewDecoder(r.Body).Decode(dtmd); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	team, err := mongodb.Teams.DeleteTeamMember(id, *dtmd)
	if err != nil{
		http.Error(w, "Team or member not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(team)
}