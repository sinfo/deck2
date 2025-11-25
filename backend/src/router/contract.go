package router

import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"fmt"
	"html"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"unicode/utf16"

	gooxml "baliance.com/gooxml"
	docx "baliance.com/gooxml/document"
	"github.com/gorilla/mux"
	"github.com/phpdave11/gofpdf"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	contractPTURL  = "https://sinfo-staging.ams3.cdn.digitaloceanspaces.com/deck2-dev/sinfo-33/contract/Contrato_participação.docx"
	contractENGURL = "https://sinfo-staging.ams3.cdn.digitaloceanspaces.com/deck2-dev/sinfo-33/contract/Participation_Contract.docx"
)

type contractRequest struct {
	Language       string `json:"language"`
	CompanyNif     string `json:"companyNif"`
	CompanyAddress string `json:"companyAddress"`
	CompanyName    string `json:"companyName"`
	PackageName    string `json:"packageName"`
	PackagePrice   string `json:"packagePrice"`
}

// generateCompanyContractPDF downloads a DOCX template, replaces variables and returns a PDF stream.
func generateCompanyContractPDF(w http.ResponseWriter, r *http.Request) {
	// Disable verbose logging from gooxml (library prints warnings about
	// unsupported Office XML elements which are harmless for our use).
	gooxml.DisableLogging()
	// Recover from panics to ensure we log the error and return 500.
	defer func() {
		if rec := recover(); rec != nil {
			log.Printf("panic in generateCompanyContractPDF: %v", rec)
			http.Error(w, "internal server error", http.StatusInternalServerError)
		}
	}()

	log.Printf("generateCompanyContractPDF: %s %s", r.Method, r.URL.Path)
	// Read company ID from path and fetch server-side data.
	params := mux.Vars(r)
	companyHex, ok := params["id"]
	if !ok || companyHex == "" {
		http.Error(w, "company id missing in path", http.StatusBadRequest)
		return
	}

	companyID, err := primitive.ObjectIDFromHex(companyHex)
	if err != nil {
		log.Printf("invalid company id '%s': %v", companyHex, err)
		http.Error(w, "invalid company id", http.StatusBadRequest)
		return
	}

	company, err := mongodb.Companies.GetCompany(companyID)
	if err != nil {
		log.Printf("unable to find company %s: %v", companyID.Hex(), err)
		http.Error(w, "unable to find company: "+err.Error(), http.StatusNotFound)
		return
	}

	defer r.Body.Close()

	var req contractRequest
	// body is optional; if present it may contain language
	_ = json.NewDecoder(r.Body).Decode(&req)

	templateURL := contractENGURL
	if strings.ToLower(req.Language) == "pt" || strings.ToLower(req.Language) == "pt-pt" || strings.ToLower(req.Language) == "pt_br" {
		templateURL = contractPTURL
	}

	resp, err := http.Get(templateURL)
	if err != nil || resp.StatusCode >= 400 {
		if err != nil {
			log.Printf("error downloading template %s: %v", templateURL, err)
		} else {
			log.Printf("error downloading template %s: status=%d", templateURL, resp.StatusCode)
		}
		http.Error(w, "unable to download template", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Printf("unable to read template body from %s: %v", templateURL, err)
		http.Error(w, "unable to read template", http.StatusInternalServerError)
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

	// package info: try to fetch participation package name
	packageName := ""
	packagePrice := ""
	if len(company.Participations) > 0 {
		p := company.Participations[0]
		if p.Package != nil {
			if pkg, err := mongodb.Packages.GetPackage(*p.Package); err == nil {
				packageName = pkg.Name
				// pkg.Price is in cents (int). Format as euros with cents.
				packagePrice = fmt.Sprintf("%d.%02d€", pkg.Price/100, pkg.Price%100)
			}
		}
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
		log.Printf("replaceDocxPlaceholders error: %v", err)
		http.Error(w, "error processing template", http.StatusInternalServerError)
		return
	}

	// extract styled paragraphs from modified docx and render a PDF (basic styling)
	paragraphs, err := extractStyledParagraphsFromDocx(modifiedDocx)
	if err != nil {
		// fallback: try plain-text extraction and render a simple pdf
		text, err2 := extractPlainTextFromDocx(modifiedDocx)
		if err2 != nil {
			log.Printf("extractStyledParagraphsFromDocx failed: %v; extractPlainTextFromDocx also failed: %v", err, err2)
			http.Error(w, "error extracting text from template", http.StatusInternalServerError)
			return
		}
		pdfBytes, err := renderPDFfromText(text)
		if err != nil {
			log.Printf("renderPDFfromText error: %v", err)
			http.Error(w, "error generating pdf", http.StatusInternalServerError)
			return
		}
		filename := fmt.Sprintf("contract-%s.pdf", sanitizeFilename(companyName))
		w.Header().Set("Content-Type", "application/pdf")
		w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
		w.Write(pdfBytes)
		return
	}

	pdfBytes, err := renderPDFfromStyledParagraphs(paragraphs)
	if err != nil {
		log.Printf("renderPDFfromStyledParagraphs error: %v", err)
		http.Error(w, "error generating pdf", http.StatusInternalServerError)
		return
	}

	filename := fmt.Sprintf("contract-%s.pdf", sanitizeFilename(companyName))

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
	w.Write(pdfBytes)
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
	r, err := zip.NewReader(bytes.NewReader(docxBytes), int64(len(docxBytes)))
	if err != nil {
		return nil, err
	}

	buf := new(bytes.Buffer)
	zw := zip.NewWriter(buf)
	defer zw.Close()

	for _, f := range r.File {
		fr, err := f.Open()
		if err != nil {
			return nil, err
		}
		data, err := ioutil.ReadAll(fr)
		fr.Close()
		if err != nil {
			return nil, err
		}

		name := f.Name

		// only attempt replacements in word document parts
		if name == "word/document.xml" || strings.HasPrefix(name, "word/header") || strings.HasPrefix(name, "word/footer") {
			s := string(data)
			s = replacePlaceholdersInXML(s, replacements, plain)
			data = []byte(s)
		}

		// prepare header
		fh := &zip.FileHeader{
			Name:   name,
			Method: f.Method,
		}
		fh.SetModTime(f.Modified)

		w, err := zw.CreateHeader(fh)
		if err != nil {
			return nil, err
		}
		if _, err := w.Write(data); err != nil {
			return nil, err
		}
	}

	if err := zw.Close(); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func xmlEscape(s string) string {
	// basic replacements for ampersand and angle brackets
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	return s
}

// replacePlaceholdersInXML does a best-effort replacement of placeholders inside
// the raw Word XML parts. It is intentionally simple: it replaces exact matches
// of placeholders (with or without braces) and XML-escapes the replacement text.
// Note: this does not handle placeholders split across runs — gooxml parsing
// is used after replacement for more accurate text extraction.
func replacePlaceholdersInXML(s string, replacements map[string]string, plain map[string]string) string {
	for k, v := range replacements {
		s = strings.ReplaceAll(s, k, xmlEscape(v))
	}
	for k, v := range plain {
		// match {{key}} and key
		s = strings.ReplaceAll(s, "{{"+k+"}}", xmlEscape(v))
		s = strings.ReplaceAll(s, k, xmlEscape(v))
	}
	return s
}

// utf16beHex returns a PDF hex string literal for the given UTF-8 string
// using UTF-16BE with BOM (FEFF). Example output: <FEFF00E700E9>
func utf16beHex(s string) string {
	runes := []rune(s)
	u16 := utf16.Encode(runes)
	buf := bytes.Buffer{}
	buf.WriteString("<FEFF")
	for _, v := range u16 {
		hi := byte(v >> 8)
		lo := byte(v & 0xff)
		buf.WriteString(fmt.Sprintf("%02X%02X", hi, lo))
	}
	buf.WriteString(">")
	return buf.String()
}

func extractPlainTextFromDocx(docxBytes []byte) (string, error) {
	r, err := zip.NewReader(bytes.NewReader(docxBytes), int64(len(docxBytes)))
	if err != nil {
		return "", err
	}

	var docXml []byte
	for _, f := range r.File {
		if f.Name == "word/document.xml" {
			fr, err := f.Open()
			if err != nil {
				return "", err
			}
			docXml, err = ioutil.ReadAll(fr)
			fr.Close()
			if err != nil {
				return "", err
			}
			break
		}
	}

	if len(docXml) == 0 {
		return "", fmt.Errorf("document.xml not found")
	}

	// strip tags
	re := regexp.MustCompile("<[^>]+>")
	text := re.ReplaceAllString(string(docXml), "")
	// unescape html entities
	text = html.UnescapeString(text)

	// normalize whitespace a bit
	text = strings.ReplaceAll(text, "\r", "")
	text = strings.ReplaceAll(text, "\n\n", "\n")

	// ensure fallback if empty
	if strings.TrimSpace(text) == "" {
		return "", fmt.Errorf("extracted empty text")
	}

	return text, nil
}

func renderPDFfromText(text string) ([]byte, error) {
	// very small PDF writer using built-in Helvetica; suitable for simple text contracts
	lines := strings.Split(text, "\n")

	buf := new(bytes.Buffer)
	// PDF header
	buf.WriteString("%PDF-1.4\n%\xE2\xE3\xCF\xD3\n")

	objs := make([][]byte, 0)

	objs = append(objs, []byte("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"))
	objs = append(objs, []byte("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"))
	page := "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n"
	objs = append(objs, []byte(page))
	objs = append(objs, []byte("4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"))

	var contentBuf bytes.Buffer
	contentBuf.WriteString("BT\n/F1 12 Tf\n50 800 Td\n")
	for i, line := range lines {
		// escape parentheses and backslashes
		esc := strings.ReplaceAll(line, "\\", "\\\\")
		esc = strings.ReplaceAll(esc, "(", "\\(")
		esc = strings.ReplaceAll(esc, ")", "\\)")
		if i > 0 {
			// move to next line using T*
			contentBuf.WriteString("T* ")
		}
		contentBuf.WriteString(fmt.Sprintf("(%s) Tj\n", esc))
	}
	contentBuf.WriteString("ET\n")

	contentBytes := contentBuf.Bytes()
	stream := fmt.Sprintf("5 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n", len(contentBytes), contentBytes)
	objs = append(objs, []byte(stream))

	offsets := make([]int, len(objs)+1)
	for i, o := range objs {
		offsets[i+1] = buf.Len()
		buf.Write(o)
	}

	xrefStart := buf.Len()
	buf.WriteString("xref\n")
	buf.WriteString(fmt.Sprintf("0 %d\n", len(objs)+1))
	buf.WriteString("0000000000 65535 f \n")
	for i := 1; i <= len(objs); i++ {
		buf.WriteString(fmt.Sprintf("%010d 00000 n \n", offsets[i]))
	}

	buf.WriteString("trailer\n<< /Size ")
	buf.WriteString(fmt.Sprintf("%d", len(objs)+1))
	buf.WriteString(" /Root 1 0 R >>\nstartxref\n")
	buf.WriteString(fmt.Sprintf("%d\n%%%%EOF", xrefStart))

	return buf.Bytes(), nil
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
