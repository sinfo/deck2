package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gookit/color"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/router"
	"github.com/sinfo/deck2/src/spaces"
)

func main() {

	config.InitializeConfig()

	if len(os.Args) == 2 {
		if os.Args[1] == "--production" {
			color.New(color.FgWhite, color.BgRed).Println("*** WARNING: RUNNING IN PRODUCTION ***")
			fmt.Println("")
			config.Production = true
		}
	}

	if err := auth.InitializeOAuth2(); err != nil {
		log.Fatal(err.Error())
	}

	auth.InitializeJWT()
	mongodb.InitializeDatabase()
	spaces.InitializeSpaces()
	router.InitializeRouter()

	log.Printf("Serving at %s:%s\n", config.Host, config.Port)
	http.ListenAndServe(fmt.Sprintf("%s:%s", config.Host, config.Port), router.Router)
}
