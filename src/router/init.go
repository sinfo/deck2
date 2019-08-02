package router

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Do stuff here
		log.Println(r.RemoteAddr, r.Method, r.RequestURI)
		// Call the next handler, which can be another middleware in the chain, or the final handler.
		next.ServeHTTP(w, r)
	})
}

func headersMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Content-Type", "application/json")
		next.ServeHTTP(w, r)
	})
}

// Router is the exported router.
var Router http.Handler

func InitializeRouter() {
	r := mux.NewRouter()

	Router = r

	r.Use(loggingMiddleware)
	r.Use(headersMiddleware)

	// company handlers
	companyRouter := r.PathPrefix("/companies").Subrouter()
	companyRouter.HandleFunc("", getCompanies).Methods("GET")
	companyRouter.HandleFunc("", createCompany).Methods("POST")

	// event handlers
	eventRouter := r.PathPrefix("/events").Subrouter()
	eventRouter.HandleFunc("", getEvents).Methods("GET")
	eventRouter.HandleFunc("", createEvent).Methods("POST")
	eventRouter.HandleFunc("", updateEvent).Methods("PUT")
	eventRouter.HandleFunc("/{id:[0-9]+}", getEvent).Methods("GET")
	eventRouter.HandleFunc("/{id:[0-9]+}", deleteEvent).Methods("DELETE")
	eventRouter.HandleFunc("/themes", updateEventThemes).Methods("PUT")

	// team handlers
	teamRouter := r.PathPrefix("/teams").Subrouter()
	teamRouter.HandleFunc("", GetTeamsHandler).Methods("GET")
	teamRouter.HandleFunc("", CreateTeamHandler).Methods("POST")
	teamRouter.HandleFunc("/{id}", GetTeamHandler).Methods("GET")
	teamRouter.HandleFunc("/{id}", DeleteTeamHandler).Methods("DELETE")

	http.ListenAndServe(":8080", r)
}
