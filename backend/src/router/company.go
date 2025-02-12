package router

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"

	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/spaces"

	"github.com/gorilla/mux"
	"github.com/h2non/filetype"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func getCompany(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	company, err := mongodb.Companies.GetCompany(companyID)

	if err != nil {
		http.Error(w, "Unable to get company:" + err.Error(), http.StatusNotFound)
	}

	json.NewEncoder(w).Encode(company)
}

func getCompanies(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetCompaniesOptions{}

	event := urlQuery.Get("event")
	partner := urlQuery.Get("partner")
	member := urlQuery.Get("member")
	name := urlQuery.Get("name")
	numRequests := urlQuery.Get("numRequests")
	maxCompInRequest := urlQuery.Get("maxCompInRequest")
	sortMethod := urlQuery.Get("sortMethod")

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.EventID = &eventID
	}

	if len(partner) > 0 {
		isPartner, err := strconv.ParseBool(partner)
		if err != nil {
			http.Error(w, "Invalid partner format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.IsPartner = &isPartner
	}

	if len(member) > 0 {
		memberID, err := primitive.ObjectIDFromHex(member)
		if err != nil {
			http.Error(w, "Invalid member ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.MemberID = &memberID
	}

	if len(name) > 0 {
		options.Name = &name
	}

	if len(numRequests) > 0 {
		numReq, err := strconv.ParseInt(numRequests, 10, 64)
		if err != nil {
			http.Error(w, "Number of Requests: Invalid Company ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.NumRequests = &numReq
	}

	if len(maxCompInRequest) > 0 {
		maxComp, err := strconv.ParseInt(maxCompInRequest, 10, 64)
		if err != nil {
			http.Error(w, "Max Companies in Request: Invalid number format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.MaxCompInRequest = &maxComp
	}

	if len(sortMethod) > 0 {
		options.SortingMethod = &sortMethod
	}

	companies, err := mongodb.Companies.GetCompanies(options)
	if err != nil {
		http.Error(w, "Unable to get companies: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(companies)
}

func getCompaniesPublic(w http.ResponseWriter, r *http.Request) {

	urlQuery := r.URL.Query()
	options := mongodb.GetCompaniesPublicOptions{}

	name := urlQuery.Get("name")
	event := urlQuery.Get("event")
	partner := urlQuery.Get("partner")

	if len(event) > 0 {
		eventID, err := strconv.Atoi(event)
		if err != nil {
			http.Error(w, "Invalid event ID format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.EventID = &eventID
	}

	if len(partner) > 0 {
		isPartner, err := strconv.ParseBool(partner)
		if err != nil {
			http.Error(w, "Invalid partner format: " + err.Error(), http.StatusBadRequest)
			return
		}
		options.IsPartner = &isPartner
	}

	if len(name) > 0 {
		options.Name = &name
	}

	publicCompanies, err := mongodb.Companies.GetPublicCompanies(options)

	if err != nil {
		log.Println(err)
		http.Error(w, "Unable to make query do database: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(publicCompanies)
}

func getCompanyPublic(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	company, err := mongodb.Companies.GetCompanyPublic(companyID)
	if err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(company)
}

func createCompany(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	var ccd = &mongodb.CreateCompanyData{}

	if err := ccd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newCompany, err := mongodb.Companies.CreateCompany(*ccd)

	if err != nil {
		http.Error(w, "Could not create company: " + err.Error(), http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(newCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreated,
			Company: &newCompany.ID,
		})
	}
}

func updateCompany(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var ucd = &mongodb.UpdateCompanyData{}

	if err := ucd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdateCompany(companyID, *ucd)

	if err != nil {
		http.Error(w, "Could not update company data: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdated,
			Company: &updatedCompany.ID,
		})
	}
}

func updateCompanyParticipation(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var ucpd = &mongodb.UpdateCompanyParticipationData{}

	if err := ucpd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdateCompanyParticipation(companyID, *ucpd)

	if err != nil {
		http.Error(w, "Could not update company data: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipation,
			Company: &updatedCompany.ID,
		})
	}
}

func deleteCompanyThread(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	params := mux.Vars(r)
	id, _ := primitive.ObjectIDFromHex(params["id"])
	threadID, _ := primitive.ObjectIDFromHex(params["threadID"])

	_, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	company, err := mongodb.Companies.DeleteCompanyThread(id, threadID)
	if err != nil {
		http.Error(w, "Company or thread not found: " + err.Error(), http.StatusNotFound)
		return
	}

	// Delete thread and posts (comments) associated to it - only if
	// thread was deleted sucessfully from speaker participation
	if _, err := mongodb.Threads.DeleteThread(threadID); err != nil {
		http.Error(w, "Thread not found: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(company)
}

func addCompanyParticipation(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	var apd = &mongodb.AddParticipationData{}

	if err := apd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	updatedCompany, err := mongodb.Companies.AddParticipation(companyID, credentials.ID, *apd)

	if err != nil {
		http.Error(w, "Could not add participation to company: " + err.Error(), http.StatusBadRequest)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreatedParticipation,
			Company: &updatedCompany.ID,
		})
	}
}

type addThreadData struct {
	Text    *string                    `json:"text"`
	Meeting *mongodb.CreateMeetingData `json:"meeting"`
	Kind    *models.ThreadKind         `json:"kind"`
}

func (acd *addThreadData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(acd); err != nil {
		return err
	}

	if acd.Text == nil {
		return errors.New("invalid text")
	}

	if acd.Kind == nil {
		return errors.New("invalid kind")
	}

	// if *acd.Kind == models.ThreadKindMeeting && acd.Meeting == nil {
	// 	return errors.New("thread kind is meeting and meeting data is not given")
	// }

	return nil
}

func addCompanyThread(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var atd = &addThreadData{}

	if err := atd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	// create the post first
	var cpd = mongodb.CreatePostData{
		Member: credentials.ID,
		Text:   *atd.Text,
	}

	newPost, err := mongodb.Posts.CreatePost(cpd)

	if err != nil {
		http.Error(w, "Could not create post: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// if applied, create the meeting
	var meetingIDPointer *primitive.ObjectID
	if *atd.Kind == models.ThreadKindMeeting {

		if err := atd.Meeting.Validate(); err != nil {
			http.Error(w, "Invalid meeting data: " + err.Error(), http.StatusBadRequest)
			return
		}

		meeting, err := mongodb.Meetings.CreateMeeting(*atd.Meeting)

		if err != nil {
			http.Error(w, "Could not create meeting: " + err.Error(), http.StatusExpectationFailed)

			// clean up the created post
			if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
				log.Printf("error deleting post: %s\n", err.Error())
			}

			return
		}

		meetingIDPointer = &meeting.ID
	}

	// only then create the thread
	var ctd = mongodb.CreateThreadData{
		Entry:   newPost.ID,
		Meeting: meetingIDPointer,
		Kind:    *atd.Kind,
	}

	newThread, err := mongodb.Threads.CreateThread(ctd)

	if err != nil {
		http.Error(w, "Could not create thread: " + err.Error(), http.StatusExpectationFailed)

		// clean up the created post and possibly meeting
		if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
			log.Printf("error deleting post: %s\n", err.Error())
		}

		if meetingIDPointer != nil {
			if _, err := mongodb.Meetings.DeleteMeeting(*meetingIDPointer); err != nil {
				log.Printf("error deleting meeting: %s\n", err.Error())
			}
		}

		return
	}

	// and finally update the company participation with the created thread
	updatedCompany, err := mongodb.Companies.AddThread(companyID, newThread.ID)

	if err != nil {
		http.Error(w, "Could not add thread to company: " + err.Error(), http.StatusExpectationFailed)

		// clean up the created post, thread and possibly meeting
		if _, err := mongodb.Posts.DeletePost(newPost.ID); err != nil {
			log.Printf("error deleting post: %s\n", err.Error())
		}

		if meetingIDPointer != nil {
			if _, err := mongodb.Meetings.DeleteMeeting(*meetingIDPointer); err != nil {
				log.Printf("error deleting meeting: %s\n", err.Error())
			}
		}

		if _, err := mongodb.Threads.DeleteThread(newThread.ID); err != nil {
			log.Printf("error deleting thread: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreated,
			Company: &updatedCompany.ID,
			Thread:  &newThread.ID,
		})
	}
}

func addCompanyPackage(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var cpd = &mongodb.CreatePackageData{}

	if err := cpd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newPackage, err := mongodb.Packages.CreatePackage(*cpd)
	if err != nil {
		http.Error(w, "Could not create new package: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdatePackage(companyID, newPackage.ID)
	if err != nil {
		http.Error(w, "Could not update company's package: " + err.Error(), http.StatusExpectationFailed)

		// delete created package
		if _, err := mongodb.Packages.DeletePackage(newPackage.ID); err != nil {
			log.Printf("error deleting package: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipationPackage,
			Company: &updatedCompany.ID,
		})
	}
}

func addCompanyParticipationBilling(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	var cbd = &mongodb.CreateBillingData{}

	if err := cbd.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	newBilling, err := mongodb.Billings.CreateBilling(*cbd)
	if err != nil {
		http.Error(w, "Error finding created billing: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdateBilling(companyID, newBilling.ID, newBilling.Event)
	if err != nil {
		http.Error(w, "Could not update company's billing: " + err.Error(), http.StatusExpectationFailed)

		// delete created billing
		if _, err := mongodb.Packages.DeletePackage(newBilling.ID); err != nil {
			log.Printf("error deleting billing: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindCreatedParticipationBilling,
			Company: &updatedCompany.ID,
		})
	}
}

func deleteCompanyParticipationBilling(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])
	billingID, _ := primitive.ObjectIDFromHex(params["billingID"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	backupBilling, _ := mongodb.Billings.GetBilling(billingID)

	updatedCompany, err := mongodb.Companies.RemoveCompanyParticipationBilling(companyID, backupBilling.Event)
	if err != nil {
		http.Error(w, "Could not remove billing from company participation: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	bill, err := mongodb.Billings.DeleteBilling(billingID)
	if err != nil {
		http.Error(w, "Billing not found: " + err.Error(), http.StatusNotFound)
		return
	}

	if err != nil {
		http.Error(w, "Could not delete billing: " + err.Error(), http.StatusExpectationFailed)

		if backupBilling == nil {
			log.Printf("no backup billing to compensate the failed deletion of the billing: %s\n", err.Error())
		}

		// create deleted billing
		if _, err := mongodb.Companies.UpdateBilling(companyID, billingID, bill.Event); err != nil {
			log.Printf("error adding billing to company participation: %s\n", err.Error())
		}

		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindDeletedParticipationBilling,
			Speaker: &updatedCompany.ID,
		})
	}
}

func deleteCompany(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	deletedCompany, err := mongodb.Companies.DeleteCompany(companyID)

	if err != nil {
		http.Error(w, "Could not delete company: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(deletedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindDeleted,
			Company: &deletedCompany.ID,
		})
	}
}

func deleteCompanyParticipation(w http.ResponseWriter, r *http.Request) {
  params := mux.Vars(r)
  companyID, _ := primitive.ObjectIDFromHex(params["id"])

  if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
    http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
    return
  }

  event, err := mongodb.Events.GetCurrentEvent()
  if err != nil {
    http.Error(w, "Error finding current event: " + err.Error(), http.StatusNotFound)
    return
  }

  company, err := mongodb.Companies.DeleteCompanyParticipation(companyID, event.ID)
  if err != nil {
    http.Error(w, "Could not remove company participation: " + err.Error(), http.StatusExpectationFailed)
    return
  }

  json.NewEncoder(w).Encode(company)

}

func setCompanyStatus(w http.ResponseWriter, r *http.Request) {

	status := new(models.ParticipationStatus)

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])
	err := status.Parse(params["status"])

	if err != nil {
		http.Error(w, "Invalid status: " + err.Error(), http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdateCompanyParticipationStatus(companyID, *status)

	if err != nil {
		http.Error(w, "Could not update company status: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipationStatus,
			Company: &updatedCompany.ID,
		})
	}
}

func stepCompanyStatus(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])
	step, err := strconv.Atoi(params["step"])

	if err != nil {
		http.Error(w, "Invalid step: " + err.Error(), http.StatusBadRequest)
		return
	}

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	updatedCompany, err := mongodb.Companies.StepStatus(companyID, step)

	if err != nil {
		http.Error(w, "Could not update company status: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedParticipationStatus,
			Company: &updatedCompany.ID,
		})
	}
}

type validStepsResponse struct {
	Steps []models.ValidStep `json:"steps"`
}

func getCompanyValidSteps(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	validSteps := validStepsResponse{}

	steps, err := mongodb.Companies.GetCompanyParticipationStatusValidSteps(companyID)

	if err != nil {
		http.Error(w, "Company without participation on the current event: " + err.Error(), http.StatusBadRequest)
		return
	}

	if steps != nil {
		validSteps.Steps = *steps
	}

	json.NewEncoder(w).Encode(validSteps)
}

func setCompanyPrivateImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
		log.Printf("Exceeded file size (%v bytes)", config.ImageMaxSize)

		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		log.Println(err)

		http.Error(w, "Invalid payload!: " + err.Error(), http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > config.ImageMaxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadCompanyInternalImage(currentEvent.ID, companyID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdateCompanyInternalImage(companyID, *url)
	if err != nil {
		http.Error(w, "Couldn't update company internal image: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedPrivateImage,
			Company: &updatedCompany.ID,
		})
	}
}

func setCompanyPublicImage(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	if err := r.ParseMultipartForm(config.ImageMaxSize); err != nil {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Invalid payload: " + err.Error(), http.StatusBadRequest)
		return
	}

	// check again for file size
	// the previous check fails only if a chunk > maxSize is sent, but this tests the whole file
	if handler.Size > config.ImageMaxSize {
		http.Error(w, fmt.Sprintf("Exceeded file size (%v bytes)", config.ImageMaxSize), http.StatusBadRequest)
		return
	}

	defer file.Close()

	currentEvent, err := mongodb.Events.GetCurrentEvent()
	if err != nil {
		http.Error(w, "Couldn't fetch current event: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	// must duplicate the reader so that we can get some information first, and then pass it to the spaces package
	var buf bytes.Buffer
	checker := io.TeeReader(file, &buf)

	bytes, err := ioutil.ReadAll(checker)
	if err != nil {
		http.Error(w, "Unable to read the file: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	if !filetype.IsImage(bytes) {
		log.Print("Not an image")
		http.Error(w, "Not an image: " + err.Error(), http.StatusBadRequest)
		return
	}

	kind, err := filetype.Match(bytes)
	if err != nil {
		http.Error(w, "Unable to get file type: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	url, err := spaces.UploadCompanyPublicImage(currentEvent.ID, companyID, &buf, handler.Size, kind.MIME.Value)
	if err != nil {
		http.Error(w, fmt.Sprintf("Couldn't upload file: %v", err), http.StatusExpectationFailed)
		return
	}

	updatedCompany, err := mongodb.Companies.UpdateCompanyPublicImage(companyID, *url)
	if err != nil {
		http.Error(w, "Couldn't update company internal image: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)

	// notify
	if credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials); ok {
		mongodb.Notifications.Notify(credentials.ID, mongodb.CreateNotificationData{
			Kind:    models.NotificationKindUpdatedPublicImage,
			Company: &updatedCompany.ID,
		})
	}
}

func addEmployer(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	var ccrp = &mongodb.CreateCompanyRepData{}

	if err := ccrp.ParseBody(r.Body); err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusBadRequest)
		return
	}

	company, err := mongodb.Companies.AddEmployer(companyID, *ccrp)
	if err != nil {
		http.Error(w, "Could not parse body: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(company)
}

func removeEmployer(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])
	repID, _ := primitive.ObjectIDFromHex(params["rep"])

	company, err := mongodb.Companies.RemoveEmployer(companyID, repID)
	if err != nil {
		http.Error(w, "Could not remove employer: " + err.Error(), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(company)

}

func subscribeToCompany(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	updatedCompany, err := mongodb.Companies.Subscribe(companyID, credentials.ID)

	if err != nil {
		http.Error(w, "Could not subscribe to company: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)
}

func unsubscribeToCompany(w http.ResponseWriter, r *http.Request) {

	defer r.Body.Close()

	params := mux.Vars(r)
	companyID, _ := primitive.ObjectIDFromHex(params["id"])

	if _, err := mongodb.Companies.GetCompany(companyID); err != nil {
		http.Error(w, "Invalid company ID: " + err.Error(), http.StatusNotFound)
		return
	}

	credentials, ok := r.Context().Value(credentialsKey).(models.AuthorizationCredentials)

	if !ok {
		http.Error(w, "Could not parse credentials", http.StatusBadRequest)
		return
	}

	updatedCompany, err := mongodb.Companies.Unsubscribe(companyID, credentials.ID)

	if err != nil {
		http.Error(w, "Could not subscribe to company: " + err.Error(), http.StatusExpectationFailed)
		return
	}

	json.NewEncoder(w).Encode(updatedCompany)
}
