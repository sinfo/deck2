package spaces

import (
	"fmt"
	"io"
)

const (
	templatePath = "templates"
)

func UploadTemplateFile(event int, templateUUID string, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/%s", event, templatePath, templateUUID)
	fmt.Println(path)
	return uploadImage(path, reader, objectSize, MIME)
}
