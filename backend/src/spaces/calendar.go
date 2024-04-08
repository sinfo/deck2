package spaces

import (
	"fmt"
	"io"
)

const (
	calendarPath = "calendar"
)

func UploadCalendarFile(event int, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s", event, calendarPath)
	return uploadImage(path, reader, objectSize, MIME)
}
