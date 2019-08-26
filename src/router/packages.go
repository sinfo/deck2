package router

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func createPackage(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var cpd = &mongodb.CreatePackageData{}

	if err := cpd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	newPackage, err := mongodb.Packages.CreatePackage(*cpd)

	if err != nil {
		http.Error(w, "Could not create package", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(newPackage)
}

func updatePackageItems(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Packages.GetPackage(id); err != nil {
		http.Error(w, "Package not found", http.StatusNotFound)
		return
	}

	var upid = &mongodb.UpdatePackageItemsData{}

	if err := upid.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body", http.StatusBadRequest)
		return
	}

	updatedPackage, err := mongodb.Packages.UpdatePackageItems(id, *upid)

	if err != nil {
		http.Error(w, "Could not update package's items", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedPackage)
}

func getPackages(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetPackagesOptions{}

	name := urlQuery.Get("name")
	price := urlQuery.Get("price")
	vat := urlQuery.Get("vat")

	if len(name) > 0 {
		options.Name = &name
	}

	if len(price) > 0 {

		if p, err := strconv.Atoi(price); err == nil {
			options.Price = &p
		} else {
			http.Error(w, "Invalid query (bad price)", http.StatusBadRequest)
			return
		}

	}

	if len(vat) > 0 {

		if v, err := strconv.Atoi(vat); err == nil {
			options.VAT = &v
		} else {
			http.Error(w, "Invalid query (bad VAT)", http.StatusBadRequest)
			return
		}

	}

	packages, err := mongodb.Packages.GetPackages(options)

	if err != nil {
		http.Error(w, "Could not get packages", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(packages)
}

func getPackage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	packageID, _ := primitive.ObjectIDFromHex(params["id"])

	p, err := mongodb.Packages.GetPackage(packageID)

	if err != nil {
		http.Error(w, "Unable to get package", http.StatusNotFound)
	}

	json.NewEncoder(w).Encode(p)
}
