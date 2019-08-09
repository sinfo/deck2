package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/router"
)

func main() {

	config.InitializeConfig()

	if err := auth.InitializeOAuth2(); err != nil {
		log.Fatal(err.Error())
	}

	auth.InitializeJWT()
	mongodb.InitializeDatabase()
	router.InitializeRouter()

	fmt.Printf("Serving at %s:%s\n", config.URL, config.Port)
	http.ListenAndServe(fmt.Sprintf("%s:%s", config.URL, config.Port), router.Router)
}
