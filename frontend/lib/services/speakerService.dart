import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/participation.dart';
import 'dart:convert';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class SpeakerService extends Service {
  Future<List<PublicSpeaker>> getPublicSpeakers(
      {String? name, int? eventId}) async {
    var queryParameters = {'name': name, 'event': eventId};

    Response<String> response =
        await dio.get("/public/speakers", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<PublicSpeaker> speakers =
          responseJson.map((e) => PublicSpeaker.fromJson(e)).toList();
      return speakers;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<PublicSpeaker?> getPublicSpeaker({required String id}) async {
    Response<String> response = await dio.get("/public/speakers/" + id);
    if (response.statusCode == 200) {
      return PublicSpeaker.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<List<Speaker>> getSpeakers(
      {String? name,
      int? eventId,
      String? member,
      int? numRequestsBackend,
      int? maxSpeaksInRequest,
      SortingMethod? sortMethod}) async {
    Map<String, dynamic> queryParameters = {};
    if (eventId != null) {
      queryParameters['event'] = eventId;
    }
    if (member != null) {
      queryParameters['member'] = member;
    }
    if (name != null) {
      queryParameters['name'] = name;
    }
    if (maxSpeaksInRequest != null) {
      queryParameters['maxSpeaksInRequest'] = maxSpeaksInRequest;
    }
    if (numRequestsBackend != null) {
      queryParameters['numRequests'] = numRequestsBackend;
    }
    if (sortMethod != null && sortMethod != SortingMethod.RANDOM) {
      queryParameters['sortMethod'] = sortMethod.toString().split('.').last;
    }

    try {
      Response<String> response =
          await dio.get("/speakers", queryParameters: queryParameters);

      final responseJson = json.decode(response.data!) as List;
      List<Speaker> speakers =
          responseJson.map((e) => Speaker.fromJson(e)).toList();
      return speakers;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> createSpeaker(String bio, String name, String title) async {
    var body = {
      "bio": bio,
      "name": name,
      "title": title,
    };

    try {
      Response<String> response = await dio.post("/speakers", data: body);

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> getSpeaker({required String id}) async {
    Response<String> response = await dio.get("/speakers/" + id);
    if (response.statusCode == 200) {
      return Speaker.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<Speaker?> updateSpeaker(
      {required String id,
      String? bio,
      String? name,
      String? notes,
      String? title}) async {
    var body = {"bio": bio, "name": name, "notes": notes, "title": title};
    print(body);

    try {
      Response<String> response = await dio.put("/speakers/" + id, data: body);

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> updateInternalImageWeb(
      {required String id, required XFile image}) async {
    Uint8List file = await image.readAsBytes();
    FormData formData = FormData.fromMap(
      {
        'image': MultipartFile.fromBytes(
          file,
          filename: image.path,
          contentType: MediaType('multipart', 'form-data'),
        )
      },
    );
    try {
      Response<String> response = await dio.post(
        '/speakers/' + id + '/image/internal',
        data: formData,
      );

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    } catch (e) {
      if (e is DioError) {
        print(e.response);
      }
    }
  }

  Future<Speaker?> updateInternalImage(
      {required String id, required File image}) async {
    FormData formData =
        FormData.fromMap({'image': await MultipartFile.fromFile(image.path)});

    try {
      Response<String> response =
          await dio.post('/speakers/' + id + '/image/internal', data: formData);

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> updatePublicImage(
      {required String id, required File image}) async {
    FormData formData =
        FormData.fromMap({'image': await MultipartFile.fromFile(image.path)});

    try {
      Response<String> response = await dio
          .post('/speakers/' + id + '/image/public/speaker', data: formData);

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> updateCompanyPublicImage(
      {required String id, required File image}) async {
    FormData formData =
        FormData.fromMap({'image': await MultipartFile.fromFile(image.path)});

    try {
      Response<String> response = await dio
          .post('/speakers/' + id + '/image/public/company', data: formData);

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> updateParticipation(
      {required String id,
      String? feedback,
      String? member,
      Room? room}) async {
    var body = {
      "feedback": feedback,
      "member": member,
      "room": room != null ? room.toJson() : null
    };

    try {
      Response<String> response =
          await dio.put("/speakers/" + id + "/participation", data: body);

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> addParticipation({required String id}) async {
    try {
      Response<String> response =
          await dio.post("/speakers/" + id + "/participation");

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> removeParticipation({required String id}) async {
    try {
      Response<String> response =
          await dio.delete("/speakers/" + id + "/participation");

      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> addFlightInfo(
      {required String id,
      required bool bought,
      required int cost,
      required String from,
      required String to,
      required DateTime inbound,
      required DateTime outbound,
      required String link,
      String? notes}) async {
    var body = {
      "bought": bought,
      "cost": cost,
      "from": from,
      "to": to,
      "inbound": inbound,
      "outbound": outbound,
      "link": link,
      "notes": notes
    };

    Response<String> response = await dio
        .post("/speakers/" + id + "/participation/flightInfo", data: body);
    try {
      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> removeFlightInfo(
      {required String id, required String flightInfoId}) async {
    Response<String> response = await dio
        .delete("/speakers/" + id + "participation/flightInfo" + flightInfoId);
    try {
      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<List<ParticipationStep>> getNextParticipationSteps(
      {required String id}) async {
    Response<String> response =
        await dio.get("/speakers/$id/participation/status/next");
    try {
      final responseJson = json.decode(response.data!)['steps'] as List;
      List<ParticipationStep> participationSteps =
          responseJson.map((e) => ParticipationStep.fromJson(e)).toList();
      return participationSteps;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> updateParticipationStatus(
      {required String id, required ParticipationStatus newStatus}) async {
    Response<String> response = await dio.put(
        "/speakers/" + id + "/participation/status/" + newStatus.toString());
    try {
      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> stepParticipationStatus(
      {required String id, required int step}) async {
    Response<String> response =
        await dio.post('/speakers/$id/participation/status/$step');
    try {
      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> subscribeToSpeaker({required String id}) async {
    Response<String> response = await dio.put("/speakers/" + id + "/subscribe");
    try {
      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> unsubscribeToSpeaker({required String id}) async {
    Response<String> response =
        await dio.put("/speakers/" + id + "/unsubscribe");
    try {
      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Speaker?> addThread({
    required String id,
    required String kind,
    required String text,
    Meeting? meeting,
  }) async {
    var body = {
      "kind": kind,
      "text": text,
      "meeting": meeting != null ? meeting.toJson() : null
    };

    Response<String> response =
        await dio.post("/speakers/" + id + "/thread", data: body);
    try {
      return Speaker.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
