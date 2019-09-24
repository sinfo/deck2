package router

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
)

type contextKey int

const (
	credentialsKey contextKey = iota
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

func checkAccessLevelWrapper(required models.TeamRole) authWrapper {
	return func(handler func(w http.ResponseWriter, r *http.Request)) func(w http.ResponseWriter, r *http.Request) {

		return func(w http.ResponseWriter, r *http.Request) {

			if !config.Authentication {
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
				http.Error(w, fmt.Sprintf("Error parsing token: %v", err.Error()), http.StatusUnauthorized)
				return
			}

			authorized := auth.CheckAccessLevel(required, *credentials)

			if !authorized {
				http.Error(w, "not enough credentials", http.StatusForbidden)
				return
			}

			ctx := context.WithValue(r.Context(), credentialsKey, *credentials)

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

func InitializeRouter() {
	r := mux.NewRouter()

	if !config.Testing {
		r.Use(loggingMiddleware)
	}

	r.Use(headersMiddleware)

	allowedHeaders := handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type", "Authorization"})
	allowedOrigins := handlers.AllowedOrigins([]string{"*"})
	allowedMethods := handlers.AllowedMethods([]string{"GET", "POST", "PUT", "DELETE", "OPTIONS"})

	authMember = checkAccessLevelWrapper(models.RoleMember)
	authTeamLeader = checkAccessLevelWrapper(models.RoleTeamLeader)
	authCoordinator = checkAccessLevelWrapper(models.RoleCoordinator)
	authAdmin = checkAccessLevelWrapper(models.RoleAdmin)

	// healthcheck endpoint
	r.HandleFunc("/health", healthCheck)

	// swagger config
	r.PathPrefix("/static/").Handler(http.StripPrefix("/static/", http.FileServer(http.Dir("./static/"))))

	// public handlers
	publicRouter := r.PathPrefix("/public").Subrouter()
	publicRouter.HandleFunc("/companies", getCompaniesPublic).Methods("GET")
	publicRouter.HandleFunc("/speakers", getSpeakersPublic).Methods("GET")
	publicRouter.HandleFunc("/events", getEventsPublic).Methods("GET")
	publicRouter.HandleFunc("/members", getMembersPublic).Methods("GET")
	publicRouter.HandleFunc("/sessions", getPublicSessions).Methods("GET")

	// auth handlers
	authRouter := r.PathPrefix("/auth").Subrouter()
	authRouter.HandleFunc("/login", oauthGoogleLogin).Methods("GET")
	authRouter.HandleFunc("/callback", oauthGoogleCallback).Methods("GET")

	// company handlers
	companyRouter := r.PathPrefix("/companies").Subrouter()
	companyRouter.HandleFunc("", authMember(getCompanies)).Methods("GET")
	companyRouter.HandleFunc("", authMember(createCompany)).Methods("POST")
	companyRouter.HandleFunc("/{id}", authMember(getCompany)).Methods("GET")
	companyRouter.HandleFunc("/{id}", authMember(updateCompany)).Methods("PUT")
	companyRouter.HandleFunc("/{id}", authAdmin(deleteCompany)).Methods("DELETE")
	companyRouter.HandleFunc("/{id}/image/internal", authMember(setCompanyPrivateImage)).Methods("POST")
	companyRouter.HandleFunc("/{id}/image/public", authCoordinator(setCompanyPublicImage)).Methods("POST")
	companyRouter.HandleFunc("/{id}/participation", authMember(addCompanyParticipation)).Methods("POST")
	companyRouter.HandleFunc("/{id}/participation", authMember(updateCompanyParticipation)).Methods("PUT")
	companyRouter.HandleFunc("/{id}/participation/status/next", authMember(getCompanyValidSteps)).Methods("GET")
	companyRouter.HandleFunc("/{id}/participation/status/{status}", authAdmin(setCompanyStatus)).Methods("PUT")
	companyRouter.HandleFunc("/{id}/participation/status/{step}", authMember(stepCompanyStatus)).Methods("POST")
	companyRouter.HandleFunc("/{id}/participation/package", authCoordinator(addCompanyPackage)).Methods("POST")
	companyRouter.HandleFunc("/{id}/thread", authMember(addCompanyThread)).Methods("POST")
	companyRouter.HandleFunc("/{id}/employer", authMember(addEmployer)).Methods("POST")
	companyRouter.HandleFunc("/{id}/employer/{rep}", authMember(removeEmployer)).Methods("DELETE")

	// speaker handlers
	speakerRouter := r.PathPrefix("/speakers").Subrouter()
	speakerRouter.HandleFunc("", authMember(getSpeakers)).Methods("GET")
	speakerRouter.HandleFunc("", authMember(createSpeaker)).Methods("POST")
	speakerRouter.HandleFunc("/{id}", authMember(getSpeaker)).Methods("GET")
	speakerRouter.HandleFunc("/{id}", authMember(updateSpeaker)).Methods("PUT")
	speakerRouter.HandleFunc("/{id}/participation", authMember(addSpeakerParticipation)).Methods("POST")
	speakerRouter.HandleFunc("/{id}/participation", authMember(updateSpeakerParticipation)).Methods("PUT")
	speakerRouter.HandleFunc("/{id}/participation/status/next", authMember(getSpeakerValidSteps)).Methods("GET")
	speakerRouter.HandleFunc("/{id}/participation/status/{step}", authMember(stepSpeakerStatus)).Methods("POST")
	speakerRouter.HandleFunc("/{id}/participation/status/{status}", authAdmin(setSpeakerStatus)).Methods("PUT")
	speakerRouter.HandleFunc("/{id}/participation/flightInfo", authMember(addSpeakerFlightInfo)).Methods("POST")
	speakerRouter.HandleFunc("/{id}/participation/flightInfo/{flightInfoID}", authCoordinator(deleteSpeakerFlightInfo)).Methods("DELETE")
	speakerRouter.HandleFunc("/{id}/image/internal", authMember(setSpeakerPrivateImage)).Methods("POST")
	speakerRouter.HandleFunc("/{id}/image/public/speaker", authCoordinator(setSpeakerPublicImage)).Methods("POST")
	speakerRouter.HandleFunc("/{id}/image/public/company", authCoordinator(setSpeakerCompanyImage)).Methods("POST")
	speakerRouter.HandleFunc("/{id}/thread", authMember(addSpeakerThread)).Methods("POST")

	// flightInfo handlers
	flightInfoRouter := r.PathPrefix("/flightInfo").Subrouter()
	flightInfoRouter.HandleFunc("/{id}", authMember(getFlightInfo)).Methods("GET")
	flightInfoRouter.HandleFunc("/{id}", authMember(updateFlightInfo)).Methods("PUT")

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
	eventRouter.HandleFunc("/sessions", authCoordinator(addSessionToEvent)).Methods("POST")

	// team handlers
	teamRouter := r.PathPrefix("/teams").Subrouter()
	teamRouter.HandleFunc("", authMember(getTeams)).Methods("GET")
	teamRouter.HandleFunc("", authCoordinator(createTeam)).Methods("POST")
	teamRouter.HandleFunc("/{id}", authMember(getTeam)).Methods("GET")
	teamRouter.HandleFunc("/{id}", authAdmin(deleteTeam)).Methods("DELETE")
	teamRouter.HandleFunc("/{id}", authCoordinator(updateTeam)).Methods("PUT")
	teamRouter.HandleFunc("/{id}/members", authCoordinator(addTeamMember)).Methods("POST")
	teamRouter.HandleFunc("/{id}/members", authCoordinator(updateTeamMemberRole)).Methods("PUT")
	teamRouter.HandleFunc("/{id}/members/{memberID}", authCoordinator(deleteTeamMember)).Methods("DELETE")
	teamRouter.HandleFunc("/{id}/meetings", authMember(addTeamMeeting)).Methods("POST")
	teamRouter.HandleFunc("/{id}/meetings/{meetingID}", authTeamLeader(deleteTeamMeeting)).Methods("DELETE")

	// me handlers
	meRouter := r.PathPrefix("/me").Subrouter()
	meRouter.HandleFunc("", authMember(getMe)).Methods("GET")
	meRouter.HandleFunc("", authMember(updateMe)).Methods("PUT")
	meRouter.HandleFunc("/image", authMember(setMyImage)).Methods("POST")
	meRouter.HandleFunc("/notifications", authMember(getMyNotifications)).Methods("GET")
	meRouter.HandleFunc("/notification/{id}", authMember(deleteMyNotification)).Methods("DELETE")

	// member handlers
	memberRouter := r.PathPrefix("/members").Subrouter()
	memberRouter.HandleFunc("", authMember(getMembers)).Methods("GET")
	memberRouter.HandleFunc("", authCoordinator(createMember)).Methods("POST")
	memberRouter.HandleFunc("/{id}", authMember(getMember)).Methods("GET")
	memberRouter.HandleFunc("/{id}/role", authMember(getMemberRole)).Methods("GET")
	memberRouter.HandleFunc("/{id}", authAdmin(updateMember)).Methods("PUT")
	memberRouter.HandleFunc("/{id}", authAdmin(deleteMember)).Methods("DELETE")

	// item handlers
	itemRouter := r.PathPrefix("/items").Subrouter()
	itemRouter.HandleFunc("", authMember(getItems)).Methods("GET")
	itemRouter.HandleFunc("", authCoordinator(createItem)).Methods("POST")
	itemRouter.HandleFunc("/{id}", authMember(getItem)).Methods("GET")
	itemRouter.HandleFunc("/{id}", authCoordinator(updateItem)).Methods("PUT")

	// package handlers
	packageRouter := r.PathPrefix("/packages").Subrouter()
	packageRouter.HandleFunc("", authCoordinator(createPackage)).Methods("POST")
	packageRouter.HandleFunc("", authMember(getPackages)).Methods("GET")
	packageRouter.HandleFunc("/{id}", authMember(getPackage)).Methods("GET")
	packageRouter.HandleFunc("/{id}", authCoordinator(updatePackage)).Methods("PUT")
	packageRouter.HandleFunc("/{id}/items", authCoordinator(updatePackageItems)).Methods("PUT")

	// contact handlers
	contactRouter := r.PathPrefix("/contacts").Subrouter()
	contactRouter.HandleFunc("", authMember(getContacts)).Methods("GET")
	contactRouter.HandleFunc("/{id}", authMember(getContact)).Methods("GET")
	contactRouter.HandleFunc("/{id}", authMember(updateContact)).Methods("PUT")

	// meetings handlers
	meetingRouter := r.PathPrefix("/meetings").Subrouter()
	meetingRouter.HandleFunc("", authMember(getMeetings)).Methods("GET")
	meetingRouter.HandleFunc("", authCoordinator(createMeeting)).Methods("POST")
	meetingRouter.HandleFunc("/{id}", authMember(getMeeting)).Methods("GET")
	meetingRouter.HandleFunc("/{id}", authCoordinator(deleteMeeting)).Methods("DELETE")

	// threads handlers
	threadRouter := r.PathPrefix("/threads").Subrouter()
	threadRouter.HandleFunc("/{id}", authMember(getThread)).Methods("GET")
	threadRouter.HandleFunc("/{id}/comments", authMember(addCommentToThread)).Methods("POST")
	threadRouter.HandleFunc("/{threadID}/comments/{postID}", authMember(removeCommentFromThread)).Methods("DELETE")

	// posts handlers
	postRouter := r.PathPrefix("/posts").Subrouter()
	postRouter.HandleFunc("/{id}", authMember(getPost)).Methods("GET")
	postRouter.HandleFunc("/{id}", authMember(updatePost)).Methods("PUT")

	// sessions handlers
	sessionsRouter := r.PathPrefix("/sessions").Subrouter()
	sessionsRouter.HandleFunc("", authMember(getSessions)).Methods("GET")
	sessionsRouter.HandleFunc("/{id}", authMember(getSession)).Methods("GET")
	sessionsRouter.HandleFunc("/{id}", authCoordinator(updateSession)).Methods("PUT")

	// billings handlers
	billingsRouter := r.PathPrefix("/billings").Subrouter()
	billingsRouter.HandleFunc("", authMember(getBillings)).Methods("GET")
	billingsRouter.HandleFunc("/{id}", authCoordinator(getBilling)).Methods("GET")
	billingsRouter.HandleFunc("", authCoordinator(createBilling)).Methods("POST")
	billingsRouter.HandleFunc("/{id}", authCoordinator(updateBilling)).Methods("PUT")
	billingsRouter.HandleFunc("/{id}", authCoordinator(deleteBilling)).Methods("DELETE")

	// companyReps handlers
	repsRouter := r.PathPrefix("/companyReps").Subrouter()
	repsRouter.HandleFunc("", authMember(getCompanyReps)).Methods("GET")
	repsRouter.HandleFunc("/{id}", authMember(getCompanyRep)).Methods("GET")
	repsRouter.HandleFunc("/{id}", authMember(updateCompanyRep)).Methods("PUT")

	// save router instance
	Router = handlers.CORS(allowedHeaders, allowedOrigins, allowedMethods)(r)
}
