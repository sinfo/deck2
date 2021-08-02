import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/company.dart';
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

  Future<List<CompanyLight>> getCompanies(
      {int? event, bool? partner, String? member, String? name}) async {
    Map<String, dynamic> queryParams = {};
    if (event != null) {
      queryParams['event'] = event;
    }
    if (partner != null) {
      queryParams['partner'] = partner;
    }
    if (member != null) {
      queryParams['member'] = member;
    }
    if (name != null) {
      queryParams['name'] = name;
    }
    queryParams['event'] = 29;

    debugPrint('Fecthing companies...');
    debugPrint(dio.options.baseUrl + companyUrl);
    Response<String> res =
        await dio.get(companyUrl, queryParameters: queryParams);
    debugPrint('Fecthing companies done!');

    if (res.statusCode == 200 && res.data!.isNotEmpty) {
      final jsonRes = json.decode(res.data!) as List;
      jsonRes.forEach((element) {
        print(element);
      });
      List<CompanyLight> data =
          jsonRes.map((e) => CompanyLight.fromJson(e)).toList();
      return data;
    } else {
      // TODO: Handle Error
      print('error');
      return [];
    }
  }
}
