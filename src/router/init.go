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

	// public handlers
	publicRouter := r.PathPrefix("/public").Subrouter()
	publicRouter.HandleFunc("/events", getEventsPublic).Methods("GET")
	publicRouter.HandleFunc("/teams", getTeamsPublic).Methods("GET")
	publicRouter.HandleFunc("/teams/{id}", getTeamPublic).Methods("GET")
	publicRouter.HandleFunc("/members", getMembersPublic).Methods("GET")
	publicRouter.HandleFunc("/members/{id}", getMemberPublic).Methods("GET")

	// auth handlers
	authRouter := r.PathPrefix("/auth").Subrouter()
	authRouter.HandleFunc("/login", oauthGoogleLogin).Methods("GET")
	authRouter.HandleFunc("/callback", oauthGoogleCallback).Methods("GET")

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
	eventRouter.HandleFunc("/packages", addPackageToEvent).Methods("POST")
	eventRouter.HandleFunc("/packages/{id}", removePackageFromEvent).Methods("DELETE")
	eventRouter.HandleFunc("/packages/{id}", updatePackageFromEvent).Methods("PUT")
	eventRouter.HandleFunc("/items", addItemToEvent).Methods("POST")
	eventRouter.HandleFunc("/items/{id}", removeItemToEvent).Methods("DELETE")
	eventRouter.HandleFunc("/meetings", addMeetingToEvent).Methods("POST")
	eventRouter.HandleFunc("/meetings/{id}", removeMeetingFromEvent).Methods("DELETE")

	// team handlers
	teamRouter := r.PathPrefix("/teams").Subrouter()
	teamRouter.HandleFunc("", getTeams).Methods("GET")
	teamRouter.HandleFunc("", createTeam).Methods("POST")
	teamRouter.HandleFunc("/{id}", getTeam).Methods("GET")
	teamRouter.HandleFunc("/{id}", deleteTeam).Methods("DELETE")
	teamRouter.HandleFunc("/{id}", updateTeam).Methods("PUT")
	teamRouter.HandleFunc("/{id}/member", addTeamMember).Methods("POST")
	teamRouter.HandleFunc("/{id}/member", updateTeamMemberRole).Methods("PUT")
	teamRouter.HandleFunc("/{id}/member", deleteTeamMember).Methods("DELETE")

	// member handlers
	memberRouter := r.PathPrefix("/members").Subrouter()
	memberRouter.HandleFunc("", getMembers).Methods("GET")
	memberRouter.HandleFunc("", createMember).Methods("POST")
	memberRouter.HandleFunc("/{id}", getMember).Methods("GET")
	memberRouter.HandleFunc("/{id}", updateMember).Methods("PUT")
	memberRouter.HandleFunc("/{id}/contact", createContactMember).Methods("POST")
	memberRouter.HandleFunc("/{id}/notification", deleteMemberNotification).Methods("DELETE")

	// item handlers
	itemRouter := r.PathPrefix("/items").Subrouter()
	itemRouter.HandleFunc("", createItem).Methods("POST")

	// package handlers
	packageRouter := r.PathPrefix("/packages").Subrouter()
	packageRouter.HandleFunc("", createPackage).Methods("POST")

	// contact handlers
	contactRouter := r.PathPrefix("/contacts").Subrouter()
	contactRouter.HandleFunc("", getContacts).Methods("GET")
	contactRouter.HandleFunc("/{id}", getContact).Methods("GET")
	contactRouter.HandleFunc("/{id}", updateContact).Methods("PUT")

	// save router instance
	Router = handlers.CORS(allowedHeaders, allowedOrigins, allowedMethods)(r)
}
