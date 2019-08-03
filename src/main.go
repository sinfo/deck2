package main

import (
	"log"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/router"
)

func main() {
	mongodb.InitializeDatabase()
	router.InitializeRouter()

	log.Println("Serving at localhost:8080")
	http.ListenAndServe(":8080", router.Router)
}
