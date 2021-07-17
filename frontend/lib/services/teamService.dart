import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/service.dart';
import 'package:frontend/models/team.dart';

//FIXME: check the use of optional (? operator) in args
class teamService extends Service {
  final String baseURL = '/teams';
  /**
   * 
   * DONE teamRouter.HandleFunc("", authMember(getTeams)).Methods("GET")
	   DONE teamRouter.HandleFunc("", authCoordinator(createTeam)).Methods("POST")
	   DONE teamRouter.HandleFunc("/{id}", authMember(getTeam)).Methods("GET")
     DONE teamRouter.HandleFunc("/{id}", authAdmin(deleteTeam)).Methods("DELETE")
     DONE teamRouter.HandleFunc("/{id}", authCoordinator(updateTeam)).Methods("PUT")
     DONE teamRouter.HandleFunc("/{id}/members", authCoordinator(addTeamMember)).Methods("POST")
     DONE teamRouter.HandleFunc("/{id}/members/{memberID}", authCoordinator(updateTeamMemberRole)).Methods("PUT")
     DONE teamRouter.HandleFunc("/{id}/members/{memberID}", authCoordinator(deleteTeamMember)).Methods("DELETE")
     DONE teamRouter.HandleFunc("/{id}/meetings", authMember(addTeamMeeting)).Methods("POST")
     DONE teamRouter.HandleFunc("/{id}/meetings/{meetingID}", authTeamLeader(deleteTeamMeeting)).Methods("DELETE")
   */

  Future<List<Team>> getTeams(
      {String? name, String? member, String? memberName, int? event}) async {
    var queryParameters = {
      "name": name,
      "member": member,
      "memberName": memberName,
      "event": event
    };

    Response<String> response =
        await dio.get(baseURL, queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Team> teams = responseJson.map((e) => Team.fromJson(e)).toList();
      return teams;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Team?> createTeam(String name) async {
    var body = {
      "name": name,
    };

    Response<String> response = await dio.post(baseURL, data: body);

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Team?> getTeam(String id) async {
    Response<String> response = await dio.get(baseURL + '/$id');

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Team?> deleteTeam(String id) async {
    Response<String> response = await dio.delete(baseURL + '/$id');

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Team?> updateTeam(String id, String name) async {
    var body = {"name": name};

    Response<String> response = await dio.put(baseURL + '/$id', data: body);

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Team?> addTeamMember(String id, String member, String role) async {
    var body = {
      "member": member,
      "role": role,
    };

    Response<String> response =
        await dio.post(baseURL + '/$id' + '/members', data: body);

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  //FIXME: Check if type of member parameter is correct
  Future<Team?> updateTeamMemberRole(
      String id, String memberID, Member member, String role) async {
    var body = {
      "member": member,
      "role": role,
    };

    Response<String> response =
        await dio.put(baseURL + '/$id' + '/members' + '/$memberID', data: body);

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Team?> deleteTeamMember(String id, String memberID) async {
    Response<String> response =
        await dio.delete(baseURL + '/$id' + '/members' + '/$memberID');

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Team?> addTeamMeeting(
      String id, DateTime begin, DateTime end, String local) async {
    var body = {
      "begin": begin,
      "end": end,
      "local": local,
    };

    Response<String> response =
        await dio.post(baseURL + '/$id' + '/meetings', data: body);

    try {
      return Team.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Meeting?> deleteTeamMeeting(String id, String meetingID) async {
    Response<String> response =
        await dio.delete(baseURL + '/$id' + '/meetings' + '/$meetingID');

    try {
      return Meeting.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
