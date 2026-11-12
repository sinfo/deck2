package spaces

import (
	"fmt"
	"io"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	memberPath = "members"
)

func UploadMemberImage(event int, member primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/%s", event, memberPath, member.Hex())
	url, err := uploadImage(path, reader, objectSize, MIME)
	if err != nil {
		return nil, err
	}
	// Refresh cached member photos after replacing the object at the same path.
	versionedURL := fmt.Sprintf("%s?v=%d", *url, time.Now().UnixNano())
	return &versionedURL, nil
}
