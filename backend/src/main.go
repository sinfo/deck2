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
	"github.com/sinfo/deck2/src/spaces"
)

func main() {

	prod := flag.Bool("production", false, "Switch between production mode and dev mode")
	file := flag.String("config", "", "Config filename. If ommited, configuration is obtained via env vars")
	flag.Parse()

	config.InitializeConfig(file)

	if *prod {
		color.New(color.FgWhite, color.BgRed).Println("*** WARNING: RUNNING IN PRODUCTION ***")
		fmt.Println("")
		config.Production = true
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
