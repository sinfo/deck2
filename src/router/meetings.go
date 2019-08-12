package router

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/gorilla/mux"
)

func getMeeting(w http.ResponseWriter, r *http.Request){

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	meeting, err := mongodb.Meetings.GetMeeting(id)
	if err != nil{
		http.Error(w, "Could not find meeting", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(meeting)
}

func deleteMeeting(w http.ResponseWriter, r *http.Request){

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	meeting, err := mongodb.Meetings.DeleteMeeting(id)
	if err != nil{
		http.Error(w, "Could not find team", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(meeting)
}

func createMeeting(w http.ResponseWriter, r *http.Request){

	defer r.Body.Close()

	var cmd = mongodb.CreateMeetingData{}

	if err := cmd.ParseBody(r.Body); err != nil{
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	meeting, err := mongodb.Meetings.CreateMeeting(cmd)
	if err != nil{
		http.Error(w, "Could not create team", http.StatusExpectationFailed)
	}

	json.NewEncoder(w).Encode(meeting)
}