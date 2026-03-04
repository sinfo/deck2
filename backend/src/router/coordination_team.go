package router

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)

type createCoordinationTeamBody struct {
	Name string `json:"name"`
}

type createCoordinationTeamCoordinatorBody struct {
	Coordinator string `json:"coordinator"`
}

type addCoordinatedTeamBody struct {
	Member string `json:"member"`
}

type setCoordinatorBody struct {
	Member string `json:"member"`
	Name   string `json:"name,omitempty"`
}

func getCoordinationTeams(w http.ResponseWriter, r *http.Request) {
	teams, err := mongodb.CoordinationTeams.GetAllCoordinationTeams()
	if err != nil {
		http.Error(w, "Could not query coordination teams: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(teams)
}

func createCoordinationTeam(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	var body createCoordinationTeamCoordinatorBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	if len(body.Coordinator) == 0 {
		http.Error(w, "invalid coordinator", http.StatusBadRequest)
		return
	}

	memberID, err := primitive.ObjectIDFromHex(body.Coordinator)
	if err != nil {
		http.Error(w, "Invalid coordinator id: "+err.Error(), http.StatusBadRequest)
		return
	}

	// validate that the provided member is a coordinator for the current event
	event, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Could not determine current event: "+err.Error(), http.StatusInternalServerError)
		return
	}

	isCoordinator := false
	for _, teamID := range event.Teams {
		team, err := mongodb.Teams.GetTeam(teamID)
		if err != nil {
			continue
		}
		for _, m := range team.GetMembersByRole(models.RoleCoordinator) {
			if m.Member == memberID {
				isCoordinator = true
				break
			}
		}
		if isCoordinator {
			break
		}
	}

	if !isCoordinator {
		http.Error(w, "member is not a coordinator in the current event", http.StatusBadRequest)
		return
	}

	// fetch member to derive the team name
	member, err := mongodb.Members.GetMember(memberID)
	if err != nil {
		http.Error(w, "Could not fetch coordinator member: "+err.Error(), http.StatusInternalServerError)
		return
	}

	ct, err := mongodb.CoordinationTeams.CreateCoordinationTeam(member.Name)
	if err != nil {
		http.Error(w, "Could not create coordination team: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// set coordinator
	tm := models.TeamMember{Member: memberID, Role: models.RoleCoordinator}
	ct, err = mongodb.CoordinationTeams.SetCoordinator(ct.ID, tm, member.Name)
	if err != nil {
		http.Error(w, "Could not set coordinator: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(ct)
}

func deleteCoordinationTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid id format: "+err.Error(), http.StatusBadRequest)
		return
	}

	ct, err := mongodb.CoordinationTeams.DeleteCoordinationTeam(id)
	if err != nil {
		http.Error(w, "Could not delete coordination team: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(ct)
}

func getCoordinationTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid id format: "+err.Error(), http.StatusBadRequest)
		return
	}

	ct, err := mongodb.CoordinationTeams.GetCoordinationTeam(id)
	if err != nil {
		http.Error(w, "Could not find coordination team: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(ct)
}

func getMyCoordinationTeams(w http.ResponseWriter, r *http.Request) {
	// get credentials from context
	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)
	if !ok {
		http.Error(w, "invalid credentials", http.StatusUnauthorized)
		return
	}

	teams, err := mongodb.CoordinationTeams.GetCoordinationTeamsByCoordinator(credentials.ID)
	if err != nil {
		http.Error(w, "Could not query coordination teams: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(teams)
}

func updateCoordinationTeam(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid id format: "+err.Error(), http.StatusBadRequest)
		return
	}

	var body createCoordinationTeamBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	if len(body.Name) == 0 {
		http.Error(w, "invalid name", http.StatusBadRequest)
		return
	}

	ct, err := mongodb.CoordinationTeams.UpdateName(id, body.Name)
	if err != nil {
		http.Error(w, "Could not update coordination team: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(ct)
}

func addCoordinatedTeam(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid id format: "+err.Error(), http.StatusBadRequest)
		return
	}

	var body addCoordinatedTeamBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	memberID, err := primitive.ObjectIDFromHex(body.Member)
	if err != nil {
		http.Error(w, "Invalid member id: "+err.Error(), http.StatusBadRequest)
		return
	}

	ct, err := mongodb.CoordinationTeams.AddCoordinatedMember(id, memberID)
	if err != nil {
		http.Error(w, "Could not add coordinated team: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(ct)
}

func removeCoordinatedTeam(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid id format: "+err.Error(), http.StatusBadRequest)
		return
	}
	memberID, err := primitive.ObjectIDFromHex(params["memberID"])
	if err != nil {
		http.Error(w, "Invalid member id format: "+err.Error(), http.StatusBadRequest)
		return
	}

	ct, err := mongodb.CoordinationTeams.RemoveCoordinatedMember(id, memberID)
	if err != nil {
		http.Error(w, "Could not remove coordinated team: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(ct)
}

func setCoordinator(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid id format: "+err.Error(), http.StatusBadRequest)
		return
	}

	var body setCoordinatorBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Could not parse body: "+err.Error(), http.StatusBadRequest)
		return
	}

	memberID, err := primitive.ObjectIDFromHex(body.Member)
	if err != nil {
		http.Error(w, "Invalid member id: "+err.Error(), http.StatusBadRequest)
		return
	}

	// validate that the provided member is a coordinator for the current event
	event, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Could not determine current event: "+err.Error(), http.StatusInternalServerError)
		return
	}

	isCoordinator := false
	for _, teamID := range event.Teams {
		team, err := mongodb.Teams.GetTeam(teamID)
		if err != nil {
			continue
		}
		for _, m := range team.GetMembersByRole(models.RoleCoordinator) {
			if m.Member == memberID {
				isCoordinator = true
				break
			}
		}
		if isCoordinator {
			break
		}
	}

	if !isCoordinator {
		http.Error(w, "member is not a coordinator in the current event", http.StatusBadRequest)
		return
	}

	tm := models.TeamMember{Member: memberID, Role: models.RoleCoordinator}

	// determine name: prefer provided name (optional) else derive from member's Name
	name := body.Name
	if len(name) == 0 {
		member, err := mongodb.Members.GetMember(memberID)
		if err != nil {
			http.Error(w, "Could not fetch coordinator member: "+err.Error(), http.StatusInternalServerError)
			return
		}
		name = member.Name
	}

	ct, err := mongodb.CoordinationTeams.SetCoordinator(id, tm, name)
	if err != nil {
		http.Error(w, "Could not set coordinator: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(ct)
}

func removeCoordinator(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "Invalid id format: "+err.Error(), http.StatusBadRequest)
		return
	}
	memberID, err := primitive.ObjectIDFromHex(params["memberID"])
	if err != nil {
		http.Error(w, "Invalid member id format: "+err.Error(), http.StatusBadRequest)
		return
	}

	ct, err := mongodb.CoordinationTeams.RemoveCoordinator(id, memberID)
	if err != nil {
		http.Error(w, "Could not remove coordinator: "+err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(ct)
}
