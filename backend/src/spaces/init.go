package spaces

import (
	"context"
	"fmt"
	"io"
	"log"
	"strings"

	"github.com/digitalocean/godo"
	"github.com/minio/minio-go"
	"golang.org/x/oauth2"

	"github.com/sinfo/deck2/src/config"
)

// digitalocean personal access token
var (
	accessKey string
	secret    string
	name      string

	endpoint   string
	cdnBaseURL string

	client     *minio.Client
	pat        string
	godoClient *godo.Client
	basePath   = "deck2"
)

type TokenSource struct {
	AccessToken string
}

func (t *TokenSource) Token() (*oauth2.Token, error) {
	token := &oauth2.Token{
		AccessToken: t.AccessToken,
	}
	return token, nil
}

const (
	ssl = true
)

func InitializeSpaces() {

	accessKey = config.SpacesKey
	secret = config.SpacesSecret
	name = config.SpacesName

	if !config.Production {
		basePath = "deck2-dev"
	}
	// Initialize digitalocean client

	pat = config.DOPAT

	tokenSource := &TokenSource{
		AccessToken: pat,
	}

	oauthClient := oauth2.NewClient(context.Background(), tokenSource)
	godoClient = godo.NewClient(oauthClient)

	opt := &godo.ListOptions{}
	cdns, _, err := godoClient.CDNs.List(context.Background(), opt)
	if err != nil {
		log.Fatalf("failed listing DigitalOcean CDNs: %v", err)
	}

	if len(cdns) == 0 {
		log.Fatalf("no CDNs returned by DigitalOcean for token owner")
	}

	for _, cdn := range cdns {
		if strings.Contains(cdn.Origin, name) {
			// Determine the endpoint host by removing the bucket prefix if present.
			if strings.HasPrefix(cdn.Origin, name+".") {
				endpoint = cdn.Origin[len(name)+1:]
			} else {
				endpoint = cdn.Origin
			}

			// Prefer an explicitly configured custom domain for the CDN base URL
			if cdn.CustomDomain != "" {
				cdnBaseURL = cdn.CustomDomain
			} else {
				// Fallback: construct base URL from bucket name + endpoint
				cdnBaseURL = fmt.Sprintf("%s.%s", name, endpoint)
			}
		}
	}

	if cdnBaseURL == "" || endpoint == "" {
		log.Fatalf("no CDN or endpoint found for Spaces bucket '%s' (SpacesName=%s)", name, name)
	}

	// Initialize a client using DigitalOcean Spaces.

	client, err = minio.New(endpoint, accessKey, secret, ssl)
	if err != nil {
		log.Fatalf("failed initializing MinIO client (endpoint=%s): %v", endpoint, err)
	}

	exists, err := client.BucketExists(name)

	if err != nil {
		log.Fatalf("error checking bucket existence for '%s': %v", name, err)
	}

	if !exists {
		log.Fatal("missing bucket")
	}

}

func List(prefix string) {

	// Create a done channel to control 'ListObjectsV2' go routine.
	doneCh := make(chan struct{})

	// Indicate to our routine to exit cleanly upon return.
	defer close(doneCh)

	isRecursive := false
	objectCh := client.ListObjectsV2(name, prefix, isRecursive, doneCh)
	for object := range objectCh {
		if object.Err != nil {
			fmt.Println(object.Err)
			return
		}
		fmt.Println(object)
	}

}

func uploadImage(path string, reader io.Reader, objectSize int64, MIME string) (*string, error) {

	path = fmt.Sprintf("%s/%s", basePath, path)
	url := fmt.Sprintf("https://%s/%s", cdnBaseURL, path)

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

func deleteObject(path string) error {

	path = fmt.Sprintf("%s/%s", basePath, path)

	err := client.RemoveObject(name, path)

	if err != nil {
		return err
	}

	return nil
}
