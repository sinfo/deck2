import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/services/service.dart';

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

    Response<String> res =
        await dio.get(companyUrl, queryParameters: queryParams);

    if (res.statusCode == 200 && res.data!.isNotEmpty) {
      final jsonRes = json.decode(res.data!) as List;
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
