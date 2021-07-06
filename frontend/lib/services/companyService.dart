import 'package:frontend/services/service.dart';
/**
 *companyRouter.HandleFunc("", authMember(getCompanies)).Methods("GET")
	companyRouter.HandleFunc("", authMember(createCompany)).Methods("POST")
	companyRouter.HandleFunc("/{id}", authMember(getCompany)).Methods("GET")
	companyRouter.HandleFunc("/{id}", authMember(updateCompany)).Methods("PUT")
	companyRouter.HandleFunc("/{id}", authAdmin(deleteCompany)).Methods("DELETE")
	companyRouter.HandleFunc("/{id}/subscribe", authMember(subscribeToCompany)).Methods("PUT")
	companyRouter.HandleFunc("/{id}/unsubscribe", authMember(unsubscribeToCompany)).Methods("PUT")
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
 */

class CompanyService extends Service {
  String companyUrl = "/companies";
}
