package router

import (
	"encoding/json"
	"net/http"

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

	// check if the IDs are valid
	for _, packageItem := range *cpd.Items {
		if _, err := mongodb.Items.GetItem(packageItem.Item); err != nil {
			http.Error(w, "Item ID not valid in list of items given", http.StatusNotFound)
			return
		}
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

	// check if the IDs are valid
	for _, packageItem := range *upid.Items {
		if _, err := mongodb.Items.GetItem(packageItem.Item); err != nil {
			http.Error(w, "Item ID not valid in list of items given", http.StatusNotFound)
			return
		}
	}

	updatedPackage, err := mongodb.Packages.UpdatePackageItems(id, *upid)

	if err != nil {
		http.Error(w, "Could not update package's items", http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedPackage)
}
