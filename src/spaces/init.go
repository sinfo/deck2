package spaces

import (
	"fmt"
	"log"

	"github.com/minio/minio-go"

	"github.com/sinfo/deck2/src/config"
)

var accessKey string
var secret string
var name string
var region string

var endpoint string

var client *minio.Client

const (
	baseURL  = "https://static.sinfo.org"
	basePath = "deck2"
	ssl      = true
)

func InitializeSpaces() {

	var err error

	accessKey = config.SpacesKey
	secret = config.SpacesSecret
	name = config.SpacesName
	region = config.SpacesRegion

	endpoint = fmt.Sprintf("%s.digitaloceanspaces.com", region)

	// Initiate a client using DigitalOcean Spaces.
	client, err = minio.New(endpoint, accessKey, secret, ssl)
	if err != nil {
		log.Fatal(err)
	}

	exists, err := client.BucketExists(name)

	if err != nil {
		log.Fatal(err)
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
