package router

import (
	"encoding/json"
	"net/http"

	"github.com/sinfo/deck2/src/mongodb"
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
