package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"text/template"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/patrickmn/go-cache"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type testPage struct {
	Speaker    string
	MemberName string
	Company    string
}

var templateCache = cache.New(1*time.Minute, 10*time.Minute)

func getFilledTemplate(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	uuid, _ := params["uuid"]

	w.Header().Set("Content-Type", "text/html")

	template, found := templateCache.Get(uuid)
	if found {
		fmt.Fprint(w, template)
		return
	} else {
		http.Error(w, "Template unavailable", http.StatusNotFound)
		return
	}
}

func fillTemplate(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	templateId, _ := primitive.ObjectIDFromHex(params["id"])

	templateObject, err := mongodb.Templates.GetTemplate(templateId)
	if err != nil {
		http.Error(w, "Unable to get template", http.StatusNotFound)
		return
	}

	defer r.Body.Close()

	var ftd = &mongodb.TemplateData{}

	if err := ftd.ParseFillBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	tPage := testPage{}

	for _, req := range *ftd.Requirements {
		// TODO refactor executions of template
		if req.Name == "speakerName" {
			tPage.Speaker = req.StringValue
		} else if req.Name == "userName" {
			tPage.MemberName = req.StringValue
		} else if req.Name == "companyName" {
			tPage.Company = req.StringValue
		}
	}

	resp, err := http.Get(templateObject.Url)
	if err != nil {
		http.Error(w, "Unable to download template", http.StatusNotFound)
		return
	}
	defer resp.Body.Close()

	b, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Unable to download template", http.StatusExpectationFailed)
		return
	}

	t, err := template.New("template").Parse(string(b))
	if err != nil {
		http.Error(w, "Error parsing template", http.StatusExpectationFailed)
		return
	}

	buf := new(bytes.Buffer)
	err = t.Execute(buf, tPage)

	if err != nil {
		http.Error(w, "Error executing template", http.StatusExpectationFailed)
		return
	}

	uuid := uuid.New()
	templateCache.Set(uuid.String(), buf.String(), cache.DefaultExpiration)

	json.NewEncoder(w).Encode(uuid.String())
}

func getTemplates(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetTemplatesOptions{}

	event := urlQuery.Get("event")
	name := urlQuery.Get("name")

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format", http.StatusBadRequest)
			return
		}
		options.EventID = &eventID
	}

	if len(name) > 0 {
		options.Name = &name
	}

	templates, err := mongodb.Templates.GetTemplates(options)
	if err != nil {
		http.Error(w, "Unable to get templates", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(templates)
}
