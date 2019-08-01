package main

import (
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/router"
)

func main() {
	mongodb.InitializeDatabase()
	router.InitializeRouter()

	http.ListenAndServe(":8080", router.Router)
}
