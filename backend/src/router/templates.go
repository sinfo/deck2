package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strconv"
	"text/template"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/patrickmn/go-cache"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/spaces"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type testPage struct {
	Speaker        string
	MemberName     string
	Company        string
	Paragraph      string
	Edition        int
	EditionOrdinal string
	EventStart     time.Time
	EventEnd       time.Time
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
		} else if req.Name == "initialParagraph" {
			tPage.Paragraph = req.StringValue
		} else if req.Name == "eventEdition" {
			tPage.Edition = req.IntegerValue
		} else if req.Name == "eventEditionOrdinal" {
			tPage.EditionOrdinal = addOrdinal(req.IntegerValue)
		} else if req.Name == "eventStart" {
			tPage.EventStart = req.DateValue
		} else if req.Name == "eventEnd" {
			tPage.EventEnd = req.DateValue
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

func addOrdinal(n int) string {
	if n >= 11 && n <= 13 {
		return fmt.Sprintf("%dth", n)
	}

	switch n % 10 {
	case 1:
		return fmt.Sprintf("%dst", n)
	case 2:
		return fmt.Sprintf("%dnd", n)
	case 3:
		return fmt.Sprintf("%drd", n)
	default:
		return fmt.Sprintf("%dth", n)
	}
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

// uploadTemplateFile uploads the provided file to Spaces for the given template ID
// and associates the returned CDN URL with the template document in DB. Requires
// query parameter `event` (integer) to determine the event (edition) path.
func uploadTemplateFile(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	templateId, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "invalid template id", http.StatusBadRequest)
		return
	}

	eventStr := r.URL.Query().Get("event")
	if eventStr == "" {
		http.Error(w, "missing event query parameter", http.StatusBadRequest)
		return
	}

	eventID, err := strconv.Atoi(eventStr)
	if err != nil {
		http.Error(w, "invalid event id", http.StatusBadRequest)
		return
	}

	// Parse multipart form
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		http.Error(w, "invalid multipart form", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "file field is required", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Read file bytes
	b, err := ioutil.ReadAll(file)
	if err != nil {
		http.Error(w, "unable to read file", http.StatusInternalServerError)
		return
	}

	// upload to spaces
	mime := header.Header.Get("Content-Type")
	if mime == "" {
		mime = "application/octet-stream"
	}

	url, err := spaces.UploadTemplateFile(eventID, templateId.Hex(), bytes.NewReader(b), int64(len(b)), mime)
	if err != nil {
		http.Error(w, "unable to upload to spaces", http.StatusBadGateway)
		return
	}

	// update template url in DB
	updated, err := mongodb.Templates.UpdateTemplateUrl(templateId, *url)
	if err != nil {
		http.Error(w, "unable to update template url in db", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updated)
}

// downloadTemplateFile streams the template file stored at template.Url as an attachment.
func downloadTemplateFile(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	templateId, err := primitive.ObjectIDFromHex(params["id"])
	if err != nil {
		http.Error(w, "invalid template id", http.StatusBadRequest)
		return
	}

	tmpl, err := mongodb.Templates.GetTemplate(templateId)
	if err != nil {
		http.Error(w, "template not found", http.StatusNotFound)
		return
	}

	if tmpl.Url == "" {
		http.Error(w, "template has no associated file URL", http.StatusNotFound)
		return
	}

	resp, err := http.Get(tmpl.Url)
	if err != nil || resp.StatusCode >= 400 {
		http.Error(w, "unable to download template file", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Use the template name as filename fallback
	filename := tmpl.Name
	if filename == "" {
		filename = "template.docx"
	}

	w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))

	io.Copy(w, resp.Body)
}
