package main

import (
	"github.com/sinfo/deck2/src/mongodb"
	"github.com/sinfo/deck2/src/server"
)

func main() {
	mongodb.InitializeDatabase()
	server.InitializeServer()
}
