package main

import (
	"log"
	"net/http"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/router"
	"github.com/spf13/viper"
)

func main() {

	// setup environment
	viper.SetEnvPrefix("DECK2")
	viper.AutomaticEnv()

	if err := auth.InitializeOAuth2(); err != nil {
		log.Fatal(err.Error())
	}

	if err := auth.InitializeJWT(); err != nil {
		log.Fatal(err.Error())
	}

	mongodb.InitializeDatabase()
	router.InitializeRouter()

	log.Println("Serving at localhost:8080")
	http.ListenAndServe(":8080", router.Router)
}
