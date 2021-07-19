import 'dart:convert';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';
import 'package:frontend/components/deckException.dart';
import 'dart:io';

class MeetingService extends Service {
  Future<List<Meeting>> getMeetings(
      {team: String, company: String, event: int}) async {
    var queryParameters = {'team': team, 'company': company, 'event': event};

    Response<String> response =
        await dio.get("/meetings", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Meeting> meetings =
          responseJson.map((e) => Meeting.fromJson(e)).toList();
      return meetings;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Meeting> createMeeting(DateTime begin, DateTime end, String place,
      MeetingParticipants participants) async {
    var body = {
      "begin": begin,
      "end": end,
      "place": place,
      "participants": participants
    };

    Response<String> response = await dio.post("/meetings", data: body);

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

  Future<Meeting> getMeeting(String id) async {
    Response<String> response = await dio.get("/meetings/" + id);

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

  Future<Meeting> deleteMeeting(String id) async {
    Response<String> response = await dio.delete("/meetings/" + id);
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

  Future<Meeting> updateMeeting(
    String id,
    DateTime begin,
    DateTime end,
    String place,
    //, MeetingParticipants participants
  ) async {
    var body = {
      "begin": begin,
      "end": end,
      "place": place
      //, "participants" : participants
    };

    Response<String> response = await dio.put("/meetings/" + id, data: body);
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

  // Future<Meeting> uploadMeetingMinute(String id, String minute) async {
  //   // TODO: Implement : https://pub.dev/packages/dio
  // }
}
