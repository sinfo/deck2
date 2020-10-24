import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/service.dart';

class SpeakerService extends Service {
  Future<List<Speaker>> getSpeakers({String name, int eventId}) async {
    var queryParameters = {'name': name, 'event': eventId};

    Response<String> response =
        await dio.get("/speakers", queryParameters: queryParameters);

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.data) as List;
      List<Speaker> speakers =
          responseJson.map((e) => Speaker.fromJson(e)).toList();
      return speakers;
    } else {
      print("error");
      return [];
    }
  }
}
