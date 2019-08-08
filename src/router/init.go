package router

import (
	"context"
	"log"
	"net/http"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/models"
)

type ContextKey int

const (
	CredentialsKey ContextKey = iota
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

type authWrapper func(func(w http.ResponseWriter, r *http.Request)) func(w http.ResponseWriter, r *http.Request)

func checkAccessLevelWrapper(required models.TeamRole, skip bool) authWrapper {
	return func(handler func(w http.ResponseWriter, r *http.Request)) func(w http.ResponseWriter, r *http.Request) {

		return func(w http.ResponseWriter, r *http.Request) {

			if skip {
				handler(w, r)
				return
			}

			token := r.Header.Get("Authorization")

			if len(token) == 0 {
				http.Error(w, "invalid token", http.StatusUnauthorized)
				return
			}

			credentials, err := auth.ParseJWT(token)

			if err != nil {
				http.Error(w, err.Error(), http.StatusUnauthorized)
				return
			}

			authorized := auth.CheckAccessLevel(required, *credentials)

			if !authorized {
				http.Error(w, "not enough credentials", http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), CredentialsKey, *credentials)

			handler(w, r.WithContext(ctx))
		}

	}
}

var (
	authMember      authWrapper
	authTeamLeader  authWrapper
	authCoordinator authWrapper
	authAdmin       authWrapper
)

func healthCheck(w http.ResponseWriter, req *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// Router is the exported router.
var Router http.Handler

func InitializeRouter(testEnv bool) {
	r := mux.NewRouter()

	if !testEnv {
		r.Use(loggingMiddleware)
	}

	r.Use(headersMiddleware)

	allowedHeaders := handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type", "Authorization"})
	allowedOrigins := handlers.AllowedOrigins([]string{"*"})
	allowedMethods := handlers.AllowedMethods([]string{"GET", "POST", "PUT", "DELETE"})

	authMember = checkAccessLevelWrapper(models.RoleMember, testEnv)
	authTeamLeader = checkAccessLevelWrapper(models.RoleTeamLeader, testEnv)
	authCoordinator = checkAccessLevelWrapper(models.RoleCoordinator, testEnv)
	authAdmin = checkAccessLevelWrapper(models.RoleAdmin, testEnv)

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
	companyRouter.HandleFunc("", authMember(getCompanies)).Methods("GET")
	companyRouter.HandleFunc("", authMember(createCompany)).Methods("POST")

	// event handlers
	eventRouter := r.PathPrefix("/events").Subrouter()
	eventRouter.HandleFunc("", authMember(getEvents)).Methods("GET")
	eventRouter.HandleFunc("", authAdmin(createEvent)).Methods("POST")
	eventRouter.HandleFunc("", authCoordinator(updateEvent)).Methods("PUT")
	eventRouter.HandleFunc("/{id:[0-9]+}", authMember(getEvent)).Methods("GET")
	eventRouter.HandleFunc("/{id:[0-9]+}", authAdmin(deleteEvent)).Methods("DELETE")
	eventRouter.HandleFunc("/themes", authCoordinator(updateEventThemes)).Methods("PUT")
	eventRouter.HandleFunc("/packages", authCoordinator(addPackageToEvent)).Methods("POST")
	eventRouter.HandleFunc("/packages/{id}", authCoordinator(removePackageFromEvent)).Methods("DELETE")
	eventRouter.HandleFunc("/packages/{id}", authCoordinator(updatePackageFromEvent)).Methods("PUT")
	eventRouter.HandleFunc("/items", authCoordinator(addItemToEvent)).Methods("POST")
	eventRouter.HandleFunc("/items/{id}", authCoordinator(removeItemToEvent)).Methods("DELETE")
	eventRouter.HandleFunc("/meetings", authCoordinator(addMeetingToEvent)).Methods("POST")
	eventRouter.HandleFunc("/meetings/{id}", authCoordinator(removeMeetingFromEvent)).Methods("DELETE")

	// team handlers
	teamRouter := r.PathPrefix("/teams").Subrouter()
	teamRouter.HandleFunc("", authMember(getTeams)).Methods("GET")
	teamRouter.HandleFunc("", authCoordinator(createTeam)).Methods("POST")
	teamRouter.HandleFunc("/{id}", authMember(getTeam)).Methods("GET")
	teamRouter.HandleFunc("/{id}", authAdmin(deleteTeam)).Methods("DELETE")
	teamRouter.HandleFunc("/{id}", authCoordinator(updateTeam)).Methods("PUT")
	teamRouter.HandleFunc("/{id}/member", authCoordinator(addTeamMember)).Methods("POST")
	teamRouter.HandleFunc("/{id}/member", authCoordinator(updateTeamMemberRole)).Methods("PUT")
	teamRouter.HandleFunc("/{id}/member", authCoordinator(deleteTeamMember)).Methods("DELETE")

	// member handlers
	memberRouter := r.PathPrefix("/members").Subrouter()
	memberRouter.HandleFunc("", authMember(getMembers)).Methods("GET")
	memberRouter.HandleFunc("", authCoordinator(createMember)).Methods("POST")
	memberRouter.HandleFunc("/{id}", authMember(getMember)).Methods("GET")
	memberRouter.HandleFunc("/{id}", authCoordinator(updateMember)).Methods("PUT")
	memberRouter.HandleFunc("/{id}/contact", authMember(createContactMember)).Methods("POST")
	memberRouter.HandleFunc("/{id}/notification", authAdmin(deleteMemberNotification)).Methods("DELETE")

	// item handlers
	itemRouter := r.PathPrefix("/items").Subrouter()
	itemRouter.HandleFunc("", authCoordinator(createItem)).Methods("POST")
	itemRouter.HandleFunc("/{id}", authMember(getItem)).Methods("GET")

	// package handlers
	packageRouter := r.PathPrefix("/packages").Subrouter()
	packageRouter.HandleFunc("", authCoordinator(createPackage)).Methods("POST")

	// contact handlers
	contactRouter := r.PathPrefix("/contacts").Subrouter()
	contactRouter.HandleFunc("", authMember(getContacts)).Methods("GET")
	contactRouter.HandleFunc("/{id}", authMember(getContact)).Methods("GET")
	contactRouter.HandleFunc("/{id}", authMember(updateContact)).Methods("PUT")
	contactRouter.HandleFunc("/{id}/phone", authMember(addPhone)).Methods("POST")
	contactRouter.HandleFunc("/{id}/mail", authMember(addMail)).Methods("POST")

	// save router instance
	Router = handlers.CORS(allowedHeaders, allowedOrigins, allowedMethods)(r)
}
