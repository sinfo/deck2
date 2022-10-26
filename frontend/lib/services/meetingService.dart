import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/services/service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:frontend/components/deckException.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

class MeetingService extends Service {
  Future<List<Meeting>> getMeetings(
      {String? team, String? company, int? event}) async {
    var queryParameters = {'team': team, 'company': company, 'event': event};

    try {
      Response<String> response =
          await dio.get("/meetings", queryParameters: queryParameters);

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
      String kind, String title) async {
    var body = {
      "begin": begin.toIso8601String(),
      "end": end.toIso8601String(),
      "place": place,
      "title": title,
      "kind": kind.toUpperCase()
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

  Future<Meeting> updateMeeting(String id, DateTime begin, DateTime end,
      String place, String kind, String title) async {
    var body = {
      "begin": begin.toIso8601String(),
      "end": end.toIso8601String(),
      "place": place,
      "title": title,
      "kind": kind.toUpperCase()
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

  Future<Meeting?> addThread({
    required String id,
    required String kind,
    required String text,
  }) async {
    var body = {"kind": kind, "text": text};

    Response<String> response =
        await dio.post("/meetings/" + id + "/thread", data: body);
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

  Future<Meeting?> uploadMeetingMinute(
      {required String id, required PlatformFile minute}) async {
    FormData formData;
    if (kIsWeb) {
      Uint8List file = minute.bytes!;
      formData = FormData.fromMap(
        {
          'minute': MultipartFile.fromBytes(
            file,
            filename: minute.name,
            contentType: MediaType('multipart', 'form-data'),
          )
        },
      );
    } else {
      formData = FormData.fromMap(
          {'minute': await MultipartFile.fromFile(minute.path!)});
    }

    Response<String> response =
        await dio.post('/meetings/' + id + '/minute', data: formData);
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

  Future<Meeting?> deleteMeetingMinute(String id) async {
    Response<String> response = await dio.delete('/meetings/' + id + '/minute');
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

  Future<Meeting?> addMeetingParticipant(
      {required String id,
      required String memberID,
      required String type}) async {
    var body = {"type": type, "memberID": memberID};

    Response<String> response =
        await dio.post('/meetings/' + id + '/participants', data: body);
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
