package spaces

import (
	"fmt"
	"io"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	itemPath = "items"
)

func UploadItemImage(event int, item primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/%s", event, itemPath, item.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}
