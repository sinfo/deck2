package spaces

import (
	"fmt"
	"io"

	"github.com/minio/minio-go"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	companyPath = "companies"
)

func uploadCompanyImage(public bool, event int, company primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {

	var path string

	if public {
		path = fmt.Sprintf("%s/%s/public/%s", basePath, companyPath, company.Hex())
	} else {
		path = fmt.Sprintf("%s/%s/internal/%s", basePath, companyPath, company.Hex())
	}

	url := fmt.Sprintf("%s/%s", baseURL, path)

	_, err := client.PutObject(name, path, reader, objectSize, minio.PutObjectOptions{
		ContentType: MIME,
		UserMetadata: map[string]string{
			"x-amz-acl": "public-read",
		},
	})

	if err != nil {
		return nil, err
	}

	return &url, nil
}

func UploadCompanyPublicImage(event int, company primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	return uploadCompanyImage(true, event, company, reader, objectSize, MIME)
}

func UploadCompanyInternalImage(event int, company primitive.ObjectID, reader io.Reader, objectSize int64, MIME string) (*string, error) {
	return uploadCompanyImage(false, event, company, reader, objectSize, MIME)
}
