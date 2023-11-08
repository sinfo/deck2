import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/service.dart';
import 'package:frontend/components/deckException.dart';

class CompanyRepService extends Service {
  Future<List<CompanyRep>> getCompanyReps(
      String? meeting, String? company, String? name) async {
    var queryParameters = {
      'meeting': meeting,
      'company': company,
      'name': name
    };

    Response<String> response =
        await dio.get("/companyReps", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<CompanyRep> companyReps =
          responseJson.map((e) => CompanyRep.fromJson(e)).toList();
      return companyReps;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<CompanyRep> getCompanyRep(String id) async {
    Response<String> response = await dio.get('/companyReps/$id');

    try {
      return CompanyRep.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<CompanyRep> updateCompanyRep(
      String id, String name, String contactId) async {
    var body = {
      'id': id,
      'name': name,
      'contact': contactId,
    };

    Response<String> response = await dio.put('/companyReps/$id', data: body);

    try {
      return CompanyRep.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
