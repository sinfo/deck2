package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"

	"github.com/gookit/color"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/router"
)

func main() {

	prod := flag.Bool("production", false, "Switch between production mode and dev mode")
	file := flag.String("config", ".env", "Config filename. If ommited, configuration is obtained via env vars")
	flag.Parse()

	print("Deck2 Backend\n")
	
	// Initialize configuration
	print("Initializing configuration...\n")
	config.InitializeConfig(file)

	if *prod {
		color.New(color.FgWhite, color.BgRed).Println("*** WARNING: RUNNING IN PRODUCTION ***")
		fmt.Println("")
		config.Production = true
	}

	print("Initializing OAuth2\n")
	if err := auth.InitializeOAuth2(); err != nil {
		log.Fatal(err.Error())
	}

	print("Initializing JWT\n")
	auth.InitializeJWT()

	print("Initializing MongoDB\n")
	mongodb.InitializeDatabase()

	print("Initializing Spaces\n")
	// spaces.InitializeSpaces()

	print("Initializing Router\n")
	router.InitializeRouter()

	log.Printf("Serving at %s:%s\n", config.Host, config.Port)
	http.ListenAndServe(fmt.Sprintf("%s:%s", config.Host, config.Port), router.Router)
}
