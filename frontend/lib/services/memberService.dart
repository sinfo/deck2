import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class MemberService extends Service {
  Future<List<Member>> getMembers({String? name, int? event}) async {
    var queryParameters = {
      'name': name,
      'event': event,
    };

    Response<String> response =
        await dio.get("/members", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Member> members =
          responseJson.map((e) => Member.fromJson(e)).toList();
      return members;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Member?> createMember(
      {required String istid,
      required String name,
      required String sinfoid}) async {
    var body = {
      'istid': istid,
      'name': name,
      'sinfoid': sinfoid,
    };

    Response<String> response = await dio.post("/members", data: body);

    try {
      return Member.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Member?> getMember(String id) async {
    Response<String> response = await dio.get('/members/$id');

    if (response.statusCode == 200) {
      return Member.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<Member?> updateMember(
    {required String id,
    String? istid,
    String? name}) async {
    var body = {
      "istid": istid,
      "name": name,
    };

    try {
      Response<String> response = await dio.put("/members/" + id, data: body);

      return Member.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Member?> updateImageWeb(
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
        '/members/' + id + '/image',
        data: formData,
      );

      return Member.fromJson(json.decode(response.data!));
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

  Future<Member?> updateImage(
      {required String id, required File image}) async {
    FormData formData =
        FormData.fromMap({'image': await MultipartFile.fromFile(image.path)});

    try {
      Response<String> response =
          await dio.post('/members/' + id + '/image', data: formData);

      return Member.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Member?> updateMyImageWeb(
      {required XFile image}) async {
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
        '/me/image',
        data: formData,
      );

      return Member.fromJson(json.decode(response.data!));
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

  Future<Member?> updateMyImage(
      {required File image}) async {
    FormData formData =
        FormData.fromMap({'image': await MultipartFile.fromFile(image.path)});

    try {
      Response<String> response =
          await dio.post('/me/image', data: formData);

      return Member.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Member?> deleteMember(String id) async {
    Response<String> response = await dio.delete("/members/" + id);
    try {
      return Member.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<String?> getMemberRole(String id) async {
    Response<String> response = await dio.get("/members/" + id + "/role");
    try {
      return json.decode(response.data!)["role"];
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<List<MemberParticipation>> getMemberParticipations(String id) async {
    Response<String> response =
        await dio.get("/members/" + id + "/participations");
    try {
      if (response.statusCode == 200 && response.data!.isNotEmpty) {
        final jsonRes = json.decode(response.data!) as List;
        List<MemberParticipation> data = jsonRes.map((e) => MemberParticipation.fromJson(e)).toList();
        return data;
      } else {
        return [];
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<List<Member>> getPublicMembers({String? name, int? event}) async {
    var queryParameters = {
      'name': name,
      'event': event,
    };

    Response<String> response =
        await dio.get("/public/members", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Member> members =
          responseJson.map((e) => Member.fromJson(e)).toList();
      return members;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
