package spaces

import (
	"fmt"
	"io"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	meetingPath = "meetings"
)

func UploadMeetingMinute(event int, meeting primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/%s", event, meetingPath, meeting.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}
