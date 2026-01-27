package router

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	gooxml "baliance.com/gooxml"
	docx "baliance.com/gooxml/document"
	"github.com/gorilla/mux"
	docxfill "github.com/nguyenthenguyen/docx"
	"github.com/phpdave11/gofpdf"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type contractRequest struct {
	Language string `json:"language"`
	EventID  int    `json:"eventId"`
}

func writeJSONError(w http.ResponseWriter, status int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	fmt.Fprintf(w, `{"message":%q}`, msg)
}

// generateCompanyContractDocx downloads a DOCX template, replaces variables and
// returns the filled DOCX as a download.
func generateCompanyContractDocx(w http.ResponseWriter, r *http.Request) {
	gooxml.DisableLogging()
	// Recover from panics to ensure we log the error and return 500.
	defer func() {
		if rec := recover(); rec != nil {
			http.Error(w, "internal server error", http.StatusInternalServerError)
		}
	}()

	// Read company ID from path and fetch server-side data.
	params := mux.Vars(r)
	companyHex, ok := params["id"]
	if !ok || companyHex == "" {
		writeJSONError(w, http.StatusBadRequest, "company id missing in path")
		return
	}

	companyID, err := primitive.ObjectIDFromHex(companyHex)
	if err != nil {
		writeJSONError(w, http.StatusBadRequest, "invalid company id")
		return
	}

	company, err := mongodb.Companies.GetCompany(companyID)
	if err != nil {
		writeJSONError(w, http.StatusNotFound, "unable to find company: "+err.Error())
		return
	}

	defer r.Body.Close()

	var req contractRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	// Prefer templates stored in DB (which should point to Spaces CDN).
	templateURL := ""

	// Require explicit eventId in the request. There must be exactly one
	// `companyContract` template for the given event.
	if req.EventID == 0 {
		writeJSONError(w, http.StatusBadRequest, "eventId is required")
		return
	}
	eventID := req.EventID

	// Require language in the request (e.g. "en" or "pt").
	if strings.TrimSpace(req.Language) == "" {
		writeJSONError(w, http.StatusBadRequest, "language is required")
		return
	}

	// Validate allowed language values (only 'en' and 'pt' supported).
	lowerLang := strings.ToLower(strings.TrimSpace(req.Language))
	if lowerLang != "en" && lowerLang != "pt" {
		writeJSONError(w, http.StatusUnprocessableEntity, "unsupported language; allowed values are: en, pt")
		return
	}

	opts := mongodb.GetTemplatesOptions{}
	opts.EventID = &eventID
	templates, err := mongodb.Templates.GetTemplates(opts)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "unable to retrieve templates for event")
		return
	}

	// filter to templates of kind `companyContract` (case-insensitive)
	var eventTemplates []struct{ Name, Url, Kind string }
	for _, t := range templates {
		if strings.ToLower(t.Kind) == "companycontract" {
			eventTemplates = append(eventTemplates, struct{ Name, Url, Kind string }{t.Name, t.Url, t.Kind})
		}
	}

	if len(eventTemplates) == 0 {
		writeJSONError(w, http.StatusUnprocessableEntity, fmt.Sprintf("no companyContract template found for event %d", eventID))
		return
	}

	// Among eventTemplates, pick the one that matches the requested language.
	// Allow both an EN and a PT template to exist for the same event, but require
	// exactly one template for the requested language.
	var candidates []struct{ Name, Url, Kind string }
	// language regexes
	reEn := regexp.MustCompile(`(?i)\b(en|english|ingles)\b`)
	rePt := regexp.MustCompile(`(?i)\b(pt|pt_pt|ptbr|pt_br|portuguese|portugues)\b`)
	for _, t := range eventTemplates {
		name := strings.ToLower(t.Name)
		// match name tokens against requested language
		if lowerLang == "pt" {
			if rePt.MatchString(name) {
				candidates = append(candidates, t)
			}
		} else { // en
			if reEn.MatchString(name) {
				candidates = append(candidates, t)
			}
		}
	}

	if len(candidates) == 0 {
		// no template for requested language
		writeJSONError(w, http.StatusUnprocessableEntity, fmt.Sprintf("no companyContract template found for event %d and language %s", eventID, lowerLang))
		return
	}
	if len(candidates) > 1 {
		writeJSONError(w, http.StatusConflict, fmt.Sprintf("multiple companyContract templates found for event %d and language %s; expected exactly one", eventID, lowerLang))
		return
	}

	// use the single matching template
	if candidates[0].Url == "" {
		writeJSONError(w, http.StatusUnprocessableEntity, "template has no URL")
		return
	}
	templateURL = candidates[0].Url

	// No global fallback: templates must be event-scoped and of kind `companyContract`.

	// If no template URL was resolved from DB, return an explicit JSON error.
	if templateURL == "" {
		writeJSONError(w, http.StatusUnprocessableEntity, "no template found for this event and language")
		return
	}

	resp, err := http.Get(templateURL)
	if err != nil || resp.StatusCode >= 400 {
		writeJSONError(w, http.StatusBadGateway, "unable to download template")
		return
	}
	defer resp.Body.Close()

	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "unable to read template")
		return
	}

	// Build replacements from company data (prefer billing info)
	companyName := company.Name
	companyNif := ""
	companyAddress := ""
	// BillingInfo is a struct (not a pointer). Use its fields if populated.
	if company.BillingInfo.Name != "" {
		companyName = company.BillingInfo.Name
	}
	companyNif = company.BillingInfo.TIN
	companyAddress = company.BillingInfo.Address

	packageName := ""
	packagePrice := ""
	for _, p := range company.Participations {
		if p.Event == eventID {
			if p.Package != nil {
				if pkg, err := mongodb.Packages.GetPackage(*p.Package); err == nil {
					packageName = pkg.Name
					// pkg.Price is in cents (int). Format as euros with cents.
					packagePrice = fmt.Sprintf("%d.%02d€", pkg.Price/100, pkg.Price%100)
				}
			}
			break
		}
	}

	// If no package was found for the requested event, return an explicit error.
	if packageName == "" {
		writeJSONError(w, http.StatusUnprocessableEntity, fmt.Sprintf("company has no package for event %d", eventID))
		return
	}

	replacements := map[string]string{
		"{{companyNif}}":     companyNif,
		"{{companyAddress}}": companyAddress,
		"{{companyName}}":    companyName,
		"{{packageName}}":    packageName,
		"{{packagePrice}}":   packagePrice,
	}

	// also try without braces for some templates
	replacementsPlain := map[string]string{
		"companyNif":     companyNif,
		"companyAddress": companyAddress,
		"companyName":    companyName,
		"packageName":    packageName,
		"packagePrice":   packagePrice,
	}

	modifiedDocx, err := replaceDocxPlaceholders(b, replacements, replacementsPlain)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "error processing template: "+err.Error())
		return
	}

	// Return the filled DOCX directly as a download (simpler than rendering PDF)
	filename := fmt.Sprintf("contract-%s.docx", sanitizeFilename(companyName))
	w.Header().Set("Content-Type", "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
	if _, err := w.Write(modifiedDocx); err != nil {
	}
}

func sanitizeFilename(name string) string {
	if name == "" {
		return "contract"
	}
	// keep letters, numbers, - and _
	re := regexp.MustCompile(`[^a-zA-Z0-9\-_]+`)
	s := re.ReplaceAllString(name, "-")
	s = strings.Trim(s, "-_")
	return s
}

func replaceDocxPlaceholders(docxBytes []byte, replacements map[string]string, plain map[string]string) ([]byte, error) {
	// Use github.com/nguyenthenguyen/docx to perform placeholder replacements
	// Write incoming bytes to a temp file because the library operates on files.
	tmpSrc, err := ioutil.TempFile("", "template-*.docx")
	if err != nil {
		return nil, err
	}
	tmpSrcName := tmpSrc.Name()
	defer func() {
		tmpSrc.Close()
		_ = os.Remove(tmpSrcName)
	}()

	if _, err := tmpSrc.Write(docxBytes); err != nil {
		return nil, err
	}
	if err := tmpSrc.Close(); err != nil {
		return nil, err
	}

	// Read and get editable document
	r, err := docxfill.ReadDocxFile(tmpSrcName)
	if err != nil {
		return nil, err
	}
	ed := r.Editable()

	// Apply replacements: first full-brace placeholders, then plain keys
	for k, v := range replacements {
		ed.Replace(k, v, -1)
	}
	for k, v := range plain {
		ed.Replace("{{"+k+"}}", v, -1)
		ed.Replace(k, v, -1)
	}

	// Write to a temp output file and return its bytes
	tmpOutName := tmpSrcName + ".out.docx"
	if err := ed.WriteToFile(tmpOutName); err != nil {
		return nil, err
	}
	defer func() { _ = os.Remove(tmpOutName) }()

	outBytes, err := ioutil.ReadFile(tmpOutName)
	if err != nil {
		return nil, err
	}
	return outBytes, nil
}

// Basic styled types
type Run struct {
	Text      string
	Bold      bool
	Italic    bool
	Underline bool
}

type Paragraph struct {
	Runs []Run
}

// extractStyledParagraphsFromDocx parses word/document.xml and extracts paragraphs made of runs
// with basic styling flags (bold, italic, underline). This is a lightweight parser and
// intentionally limited compared to full gooxml/unioffice feature set.
func extractStyledParagraphsFromDocx(docxBytes []byte) ([]Paragraph, error) {
	// Use gooxml (baliance.com/gooxml/document) to parse the docx and extract paragraphs and runs.
	// We write the bytes to a temp file because the gooxml API expects a file path for opening.
	tmp, err := ioutil.TempFile("", "docx-*.docx")
	if err != nil {
		return nil, err
	}
	tmpName := tmp.Name()
	defer func() {
		tmp.Close()
		_ = os.Remove(tmpName)
	}()

	if _, err := tmp.Write(docxBytes); err != nil {
		return nil, err
	}
	if err := tmp.Close(); err != nil {
		return nil, err
	}

	d, err := docx.Open(tmpName)
	if err != nil {
		return nil, err
	}

	var paragraphs []Paragraph
	for _, p := range d.Paragraphs() {
		para := Paragraph{}
		for _, r := range p.Runs() {
			// build text including breaks/tabs, since Run.Text() omits breaks
			var buf strings.Builder
			for _, ic := range r.X().EG_RunInnerContent {
				if ic.T != nil {
					buf.WriteString(ic.T.Content)
				}
				if ic.Tab != nil {
					buf.WriteByte('\t')
				}
				if ic.Br != nil {
					buf.WriteByte('\n')
				}
			}
			text := buf.String()

			rp := r.Properties()
			underline := false
			if rp.X() != nil && rp.X().U != nil {
				underline = true
			}

			run := Run{
				Text:      text,
				Bold:      rp.IsBold(),
				Italic:    rp.IsItalic(),
				Underline: underline,
			}
			para.Runs = append(para.Runs, run)
		}
		if len(para.Runs) > 0 {
			paragraphs = append(paragraphs, para)
		}
	}

	// also extract headers and footers
	for _, h := range d.Headers() {
		for _, p := range h.Paragraphs() {
			para := Paragraph{}
			for _, r := range p.Runs() {
				var buf strings.Builder
				for _, ic := range r.X().EG_RunInnerContent {
					if ic.T != nil {
						buf.WriteString(ic.T.Content)
					}
					if ic.Tab != nil {
						buf.WriteByte('\t')
					}
					if ic.Br != nil {
						buf.WriteByte('\n')
					}
				}
				text := buf.String()
				rp := r.Properties()
				underline := false
				if rp.X() != nil && rp.X().U != nil {
					underline = true
				}
				run := Run{
					Text:      text,
					Bold:      rp.IsBold(),
					Italic:    rp.IsItalic(),
					Underline: underline,
				}
				para.Runs = append(para.Runs, run)
			}
			if len(para.Runs) > 0 {
				paragraphs = append(paragraphs, para)
			}
		}
	}

	for _, f := range d.Footers() {
		for _, p := range f.Paragraphs() {
			para := Paragraph{}
			for _, r := range p.Runs() {
				var buf strings.Builder
				for _, ic := range r.X().EG_RunInnerContent {
					if ic.T != nil {
						buf.WriteString(ic.T.Content)
					}
					if ic.Tab != nil {
						buf.WriteByte('\t')
					}
					if ic.Br != nil {
						buf.WriteByte('\n')
					}
				}
				text := buf.String()
				rp := r.Properties()
				underline := false
				if rp.X() != nil && rp.X().U != nil {
					underline = true
				}
				run := Run{
					Text:      text,
					Bold:      rp.IsBold(),
					Italic:    rp.IsItalic(),
					Underline: underline,
				}
				para.Runs = append(para.Runs, run)
			}
			if len(para.Runs) > 0 {
				paragraphs = append(paragraphs, para)
			}
		}
	}

	if len(paragraphs) == 0 {
		return nil, fmt.Errorf("no paragraphs extracted")
	}
	return paragraphs, nil
}

// renderPDFfromStyledParagraphs renders basic styled paragraphs to a PDF bytes buffer.
// Supports bold/italic by switching among Type1 Helvetica variants. Wrapping and spacing
// are approximate (OSS limitation).
func renderPDFfromStyledParagraphs(pars []Paragraph) ([]byte, error) {
	// Use gofpdf with embedded DejaVu fonts (TTF) for proper Unicode support.
	// Expect fonts at backend/assets/fonts/DejaVuSans.ttf and DejaVuSans-Bold.ttf
	fontDir := filepath.Join("assets", "fonts")
	normalPath := filepath.Join(fontDir, "DejaVuSans.ttf")
	boldPath := filepath.Join(fontDir, "DejaVuSans-Bold.ttf")

	if _, err := os.Stat(normalPath); err != nil {
		return nil, fmt.Errorf("font not found: %s (place DejaVuSans.ttf in backend/assets/fonts)", normalPath)
	}
	// bold variant optional; if missing we'll use normal for bold style

	pdf := gofpdf.New("P", "mm", "A4", "")
	// Register fonts (UTF-8 aware). AddUTF8Font does not return an error.
	// Register normal and provide fallbacks for italic (I) and bold-italic (BI)
	// by reusing the available TTFs so SetFont("DejaVu","I") won't fail.
	pdf.AddUTF8Font("DejaVu", "", normalPath)
	// register italic style as same as normal if italic file not available
	pdf.AddUTF8Font("DejaVu", "I", normalPath)
	if _, err := os.Stat(boldPath); err == nil {
		pdf.AddUTF8Font("DejaVu", "B", boldPath)
		// register bold-italic to bold TTF (best effort)
		pdf.AddUTF8Font("DejaVu", "BI", boldPath)
	} else {
		// if bold not present, map BI to normal as well
		pdf.AddUTF8Font("DejaVu", "B", normalPath)
		pdf.AddUTF8Font("DejaVu", "BI", normalPath)
	}

	pdf.SetAutoPageBreak(true, 20)
	pdf.AddPage()

	lineHt := 6.0
	pdf.SetFont("DejaVu", "", 12)

	for _, p := range pars {
		for _, r := range p.Runs {
			style := ""
			if r.Bold {
				style += "B"
			}
			if r.Italic {
				style += "I"
			}
			// gofpdf will fall back to normal if B variant not registered
			pdf.SetFont("DejaVu", style, 12)
			// handle newlines inside run
			parts := strings.Split(r.Text, "\n")
			for i, part := range parts {
				if part == "" {
					pdf.Ln(lineHt)
					continue
				}
				// Write text (UTF-8)
				pdf.Write(lineHt, part)
				if i < len(parts)-1 {
					pdf.Ln(lineHt)
				}
			}
		}
		// paragraph gap
		pdf.Ln(lineHt)
	}

	var out bytes.Buffer
	if err := pdf.Output(&out); err != nil {
		return nil, err
	}
	return out.Bytes(), nil
}
