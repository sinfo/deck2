package spaces

import (
	"fmt"
	"io"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	speakerPath = "speakers"
)

func UploadSpeakerPublicImage(event int, speaker primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/public/speaker/%s", event, speakerPath, speaker.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}

func UploadSpeakerInternalImage(event int, speaker primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/internal/%s", event, speakerPath, speaker.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}

func UploadSpeakerCompanyImage(event int, speaker primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/public/company/%s", event, speakerPath, speaker.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}
