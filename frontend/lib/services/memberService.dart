import 'dart:convert';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class MemberService extends Service {
  Future<List<Member>> getMembers({String? name, int? event}) async {
    var queryParameters = {
      'name': name,
      'event': event,
    };

    Response<String> response =
        await dio.get("/members", queryParameters: queryParameters);

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.data!) as List;
      List<Member> members =
          responseJson.map((e) => Member.fromJson(e)).toList();
      return members;
    } else {
      // TODO: Handle Error
      print("error");
      return [];
    }
  }

  Future<Member?> createMember(
      String istid, String name, String sinfoid) async {
    var body = {
      "istid": istid,
      "name": name,
      "sinfoid": sinfoid,
    };

    Response<String> response = await dio.post("/members", data: body);

    if (response.statusCode == 200) {
      return Member.fromJson(json.decode(response.data!));
    } else {
      // TODO: Handle Error
      print("error");
      return null;
    }
  }

  Future<Member?> getMember(String id) async {
    Response<String> response = await dio.get("/members/" + id);

    if (response.statusCode == 200) {
      return Member.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<Member?> updateMember(String id, String istid, String name) async {
    var body = {
      "istid": istid,
      "name": name,
    };

    Response<String> response = await dio.put("/members/" + id, data: body);

    if (response.statusCode == 200) {
      return Member.fromJson(json.decode(response.data!));
    } else {
      // TODO: Handle Error
      print("error");
      return null;
    }
  }

  Future<Member?> deleteMember(String id) async {
    Response<String> response = await dio.delete("/members/" + id);
    if (response.statusCode == 200) {
      return Member.fromJson(json.decode(response.data!));
    } else {
      // TODO: Handle Error
      print("error");
      return null;
    }
  }

  Future<String?> getMemberRole(String id) async {
    Response<String> response = await dio.get("/members/" + id + "/role");
    if (response.statusCode == 200) {
      return json.decode(response.data!)["role"];
    } else {
      // TODO: Handle Error
      print("error");
      return null;
    }
  }

  Future<List<Member>> getPublicMembers({String? name, int? event}) async {
    var queryParameters = {
      'name': name,
      'event': event,
    };

    Response<String> response =
        await dio.get("/public/members", queryParameters: queryParameters);

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.data!) as List;
      List<Member> members =
          responseJson.map((e) => Member.fromJson(e)).toList();
      return members;
    } else {
      // TODO: Handle Error
      print("error");
      return [];
    }
  }
}
