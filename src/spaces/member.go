package spaces

import (
	"fmt"
	"io"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	memberPath = "members"
)

func UploadMemberImage(event int, member primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/%s", event, memberPath, member.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}
