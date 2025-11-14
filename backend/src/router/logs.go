package router

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getLogs(w http.ResponseWriter, r *http.Request) {
	// parse filters
	q := r.URL.Query()

	filter := bson.M{}

	if resource := q.Get("resource"); resource != "" {
		filter["resource"] = resource
	}

	if action := q.Get("action"); action != "" {
		filter["action"] = action
	}

	if actor := q.Get("actor"); actor != "" {
		if oid, err := primitive.ObjectIDFromHex(actor); err == nil {
			filter["actor"] = oid
		}
	}

	if ev := q.Get("event"); ev != "" {
		if eid, err := strconv.Atoi(ev); err == nil {
			// event stored as top-level field on the log
			filter["event"] = eid
		}
	}

	var limit int64 = 50
	var skip int64 = 0

	if l := q.Get("limit"); l != "" {
		if v, err := strconv.ParseInt(l, 10, 64); err == nil {
			limit = v
		}
	}

	if s := q.Get("skip"); s != "" {
		if v, err := strconv.ParseInt(s, 10, 64); err == nil {
			skip = v
		}
	}

	logs, err := mongodb.Logs.ListLogs(filter, limit, skip)
	if err != nil {
		http.Error(w, "Unable to get logs: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(logs)
}

func getLog(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	idHex := params["id"]

	id, err := primitive.ObjectIDFromHex(idHex)
	if err != nil {
		http.Error(w, "Invalid log ID: "+err.Error(), http.StatusBadRequest)
		return
	}

	lg, err := mongodb.Logs.GetLog(id)
	if err != nil {
		http.Error(w, "Log not found: "+err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(lg)
}

// getLogsBySpeaker returns logs where resource == "speaker" and resourceId == {id}
func getLogsBySpeaker(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	idHex := params["id"]

	id, err := primitive.ObjectIDFromHex(idHex)
	if err != nil {
		http.Error(w, "Invalid speaker ID: "+err.Error(), http.StatusBadRequest)
		return
	}

	filter := bson.M{"resource": "speaker", "resourceId": id}

	// reuse query params for pagination and optional event filter
	q := r.URL.Query()
	var limit int64 = 50
	var skip int64 = 0
	if l := q.Get("limit"); l != "" {
		if v, err := strconv.ParseInt(l, 10, 64); err == nil {
			limit = v
		}
	}
	if s := q.Get("skip"); s != "" {
		if v, err := strconv.ParseInt(s, 10, 64); err == nil {
			skip = v
		}
	}

	if ev := q.Get("event"); ev != "" {
		if eid, err := strconv.Atoi(ev); err == nil {
			filter["event"] = eid
		}
	}

	logs, err := mongodb.Logs.ListLogs(filter, limit, skip)
	if err != nil {
		http.Error(w, "Unable to get logs: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(logs)
}

// getLogsByCompany returns logs where resource == "company" and resourceId == {id}
func getLogsByCompany(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	idHex := params["id"]

	id, err := primitive.ObjectIDFromHex(idHex)
	if err != nil {
		http.Error(w, "Invalid company ID: "+err.Error(), http.StatusBadRequest)
		return
	}

	filter := bson.M{"resource": "company", "resourceId": id}

	q := r.URL.Query()
	var limit int64 = 50
	var skip int64 = 0
	if l := q.Get("limit"); l != "" {
		if v, err := strconv.ParseInt(l, 10, 64); err == nil {
			limit = v
		}
	}
	if s := q.Get("skip"); s != "" {
		if v, err := strconv.ParseInt(s, 10, 64); err == nil {
			skip = v
		}
	}

	if ev := q.Get("event"); ev != "" {
		if eid, err := strconv.Atoi(ev); err == nil {
			filter["event"] = eid
		}
	}

	logs, err := mongodb.Logs.ListLogs(filter, limit, skip)
	if err != nil {
		http.Error(w, "Unable to get logs: "+err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(logs)
}
