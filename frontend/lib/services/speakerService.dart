import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/service.dart';

class SpeakerService extends Service {
  Future<List<PublicSpeaker>> getPublicSpeakers(
      {String name, int eventId}) async {
    var queryParameters = {'name': name, 'event': eventId};

    Response<String> response =
        await dio.get("/public/speakers", queryParameters: queryParameters);

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.data) as List;
      List<PublicSpeaker> speakers =
          responseJson.map((e) => PublicSpeaker.fromJson(e)).toList();
      return speakers;
    } else {
      print("error");
      return [];
    }
  }

  Future<PublicSpeaker> getPublicSpeaker({String id}) async {
    //TODO: Implement this method.
  }
}
