package spaces

import (
	"fmt"
	"io"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	companyPath = "companies"
)

func UploadCompanyPublicImage(event int, company primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/public/%s", event, companyPath, company.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}

func UploadCompanyInternalImage(event int, company primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	path := fmt.Sprintf("sinfo-%d/%s/internal/%s", event, companyPath, company.Hex())
	return uploadImage(path, reader, objectSize, MIME)
}
