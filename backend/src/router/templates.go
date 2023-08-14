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

//FIXME
// func getTemplate(w http.ResponseWriter, r *http.Request) {

// params := mux.Vars(r)
// templateID, _ := primitive.ObjectIDFromHex(params["id"])

// template, err := mongodb.Companies.GetCompany(templateID)

// if err != nil {
// 	http.Error(w, "Unable to get company", http.StatusNotFound)
// }

// json.NewEncoder(w).Encode(template)

// 	absPath, _ := filepath.Abs("")

// 	b, err := os.ReadFile(absPath + "/src/router/template1.html") // just pass the file name
// 	if err != nil {
// 		fmt.Print(err)
// 	}

// 	str := string(b) // convert content to a 'string'

// 	fmt.Fprint(w, str)
// }

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

// func uploadTemplateFile(w http.ResponseWriter, r *http.Request) {
// 	defer r.Body.Close()

// 	params := mux.Vars(r)
// 	templateID, _ := primitive.ObjectIDFromHex(params["id"])

// 	if _, err := mongodb.Templates.GetTemplate(templateID); err != nil {
// 		http.Error(w, "Invalid template ID", http.StatusNotFound)
// 		return
// 	}

// 	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
// 		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
// 		return
// 	}

// 	file, handler, err := r.FormFile("template")
// 	if err != nil {
// 		http.Error(w, "Invalid payload", http.StatusBadRequest)
// 		return
// 	}

// 	// check again for file size
// 	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
// 	if handler.Size > config.ImageMaxSize {
// 		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
// 		return
// 	}

// 	defer file.Close()

// 	currentEvent, err := mongodb.Events.GetCurrentEvent()
// 	if err != nil {
// 		http.Error(w, "Couldn't fetch current event", http.StatusExpectationFailed)
// 		return
// 	}

// 	print("Current event " + strconv.Itoa(currentEvent.ID))

// 	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
// 	var buf bytes.Buffer
// 	checker := io.TeeReader(file, &buf)

// 	bytes, err := ioutil.ReadAll(checker)
// 	if err != nil {
// 		http.Error(w, "Unable to read the file", http.StatusExpectationFailed)
// 		return
// 	}

// 	templateType := mimetype.Detect(bytes)

// 	url, err := spaces.UploadTemplateFile(currentEvent.ID, templateID.Hex(), &buf, handler.Size, templateType.Extension())
// 	if err != nil {
// 		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
// 		return
// 	}

// 	updatedTemplate, err := mongodb.Templates.UpdateTemplateUrl(templateID, *url)
// 	if err != nil {
// 		http.Error(w, "Could not update url"+err.Error(), http.StatusBadRequest)
// 		return
// 	}

// 	json.NewEncoder(w).Encode(updatedTemplate)
// }

// func createTemplate(w http.ResponseWriter, r *http.Request) {
// 	defer r.Body.Close()

// 	params := mux.Vars(r)
// 	name := params["name"]

// 	var ctd = &mongodb.TemplateData{}
// 	if err := ctd.ParseCreateBody(r.Body); err != nil {
// 		http.Error(w, "Could not parse body"+err.Error(), http.StatusBadRequest)
// 		return
// 	}
// 	newTemplate, err := mongodb.Templates.CreateTemplate(*ctd, name)
// 	if err != nil {
// 		http.Error(w, "Could not create template"+err.Error(), http.StatusBadRequest)
// 		return
// 	}
// if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
// 	http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
// 	return
// }

// file, handler, err := r.FormFile("template")
// if err != nil {
// 	http.Error(w, "Invalid payload", http.StatusBadRequest)
// 	return
// }

// check again for file size
// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
// if handler.Size > config.ImageMaxSize {
// 	http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
// 	return
// }

// defer file.Close()

// currentEvent, err := mongodb.Events.GetCurrentEvent()
// if err != nil {
// 	http.Error(w, "Couldn't fetch current event", http.StatusExpectationFailed)
// 	return
// }

// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
// var buf bytes.Buffer
// checker := io.TeeReader(file, &buf)

// bytes, err := ioutil.ReadAll(checker)
// if err != nil {
// 	http.Error(w, "Unable to read the file", http.StatusExpectationFailed)
// 	return
// }

// templateType := mimetype.Detect(bytes)

// newTemplate, err := mongodb.Templates.CreateTemplate(name)
// if err != nil {
// 	http.Error(w, "Could not create template"+err.Error(), http.StatusBadRequest)
// 	return
// }

// url, err := spaces.UploadTemplateFile(currentEvent.ID, newTemplate.ID.Hex(), &buf, handler.Size, templateType.Extension())
// if err != nil {
// 	http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
// 	return
// }

// updatedTemplate, err := mongodb.Templates.UpdateTemplateUrl(newTemplate.ID, *url)
// if err != nil {
// 	http.Error(w, "Could not update url"+err.Error(), http.StatusBadRequest)
// 	return
// }

// 	json.NewEncoder(w).Encode(newTemplate)
// }

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
