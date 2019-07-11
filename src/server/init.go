package server

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Do stuff here
		log.Println(r.RequestURI)
		// Call the next handler, which can be another middleware in the chain, or the final handler.
		next.ServeHTTP(w, r)
	})
}

func InitializeServer() {
	r := mux.NewRouter()

	r.Use(loggingMiddleware)

	// company handlers
	companyRouter := r.PathPrefix("/company").Subrouter()
	companyRouter.HandleFunc("", GetCompanies).Methods("GET")
	companyRouter.HandleFunc("", CreateCompany).Methods("POST")

	http.ListenAndServe(":8080", r)
}
