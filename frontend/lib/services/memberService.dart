import 'dart:convert';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class MemberService extends Service {
  Future<List<Member>> getMembers({String name, String event}) async {
    var queryParameters = {
      'name': name,
      'event': event,
    };

    Response<String> response =
        await dio.get("/members", queryParameters: queryParameters);

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.data) as List;
      List<Member> members =
          responseJson.map((e) => Member.fromJson(e)).toList();
      return members;
    } else {
      print('error');
      return [];
    }
  }
}
