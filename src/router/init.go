package router

import (
	"log"
	"net/http"

	"github.com/gorilla/handlers"
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

func healthCheck(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// Router is the exported router.
var Router http.Handler

func InitializeRouter() {
	r := mux.NewRouter()

	r.Use(loggingMiddleware)
	r.Use(headersMiddleware)

	allowedHeaders := handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type"})
	allowedOrigins := handlers.AllowedOrigins([]string{"*"})
	allowedMethods := handlers.AllowedMethods([]string{"GET", "POST", "PUT", "DELETE"})

	// healthcheck endpoint
	r.HandleFunc("/health", healthCheck)

	// swagger config
	r.PathPrefix("/static/").Handler(http.StripPrefix("/static/", http.FileServer(http.Dir("./static/"))))

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
	teamRouter.HandleFunc("", getTeams).Methods("GET")
	teamRouter.HandleFunc("", createTeam).Methods("POST")
	teamRouter.HandleFunc("/{id}", getTeam).Methods("GET")
	teamRouter.HandleFunc("/{id}", deleteTeam).Methods("DELETE")

	// save router instance
	Router = handlers.CORS(allowedHeaders, allowedOrigins, allowedMethods)(r)
}
