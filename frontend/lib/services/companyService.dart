import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/meeting.dart';
import 'package:http_parser/http_parser.dart';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/services/service.dart';
import 'package:image_picker/image_picker.dart';

class CompanyService extends Service {
  Future<List<PublicCompany>> getPublicCompanies(
      {String? name, int? event, bool? partner}) async {
    var queryParameters = {'name': name, 'event': event, 'partner': partner};

    Response<String> response =
        await dio.get('/public/companies', queryParameters: queryParameters);
    try {
      final responseJson = json.decode(response.data!) as List;
      List<PublicCompany> speakers =
          responseJson.map((e) => PublicCompany.fromJson(e)).toList();
      return speakers;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<PublicCompany?> getPublicSpeaker({required String id}) async {
    Response<String> response = await dio.get("/public/companies/" + id);
    if (response.statusCode == 200) {
      return PublicCompany.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<List<Company>> getCompanies(
      {int? event,
      bool? partner,
      String? member,
      String? name,
      int? numRequestsBackend,
      int? maxCompInRequest,
      SortingMethod? sortMethod}) async {
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
    if (maxCompInRequest != null) {
      queryParams['maxCompInRequest'] = maxCompInRequest;
    }
    if (numRequestsBackend != null) {
      queryParams['numRequests'] = numRequestsBackend;
    }
    if (sortMethod != null && sortMethod != SortingMethod.RANDOM) {
      queryParams['sortMethod'] = sortMethod.toString().split('.').last;
    }

    String companyUrl = '/companies';
    Response<String> res =
        await dio.get(companyUrl, queryParameters: queryParams);

    if (res.statusCode == 200 && res.data!.isNotEmpty) {
      final jsonRes = json.decode(res.data!) as List;
      List<Company> data = jsonRes.map((e) => Company.fromJson(e)).toList();
      return data;
    } else {
      return [];
    }
  }

  Future<Company?> createCompany(
      {required String description,
      required String name,
      required String site}) async {
    var body = {'description': description, 'name': name, 'site': site};

    Response<String> response = await dio.post('/companies', data: body);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> getCompany({required String id}) async {
    Response<String> response = await dio.get('/companies/' + id);
    if (response.statusCode == 200) {
      return Company.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<Company?> updateCompany(
      {required String id,
      CompanyBillingInfo? billingInfo,
      String? description,
      String? name,
      String? site}) async {
    final Map<String, dynamic> body = {'description': description, 'name': name, 'site': site};

    if (billingInfo != null) {
      body['billingInfo'] = billingInfo.toJson();
    }

    Response<String> response = await dio.put('/companies/' + id, data: body);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> deleteCompany({required String id}) async {
    Response<String> response = await dio.delete('/companies/' + id);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> createRep(
      {required String id,
      required String name,
      required Contact contact}) async {
    var body = {'id': id, 'name': name, 'contact': contact.toJson()};

    Response<String> response =
        await dio.post('/companies/' + id + '/employer', data: body);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> deleteRep(
      {required String id, required String repId}) async {
    Response<String> response =
        await dio.delete('/companies/' + id + '/employer/' + repId);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> updateInternalImageWeb(
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
        '/companies/' + id + '/image/internal',
        data: formData,
      );
      return Company.fromJson(json.decode(response.data!));
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

  Future<Company?> updateInternalImage(
      {required String id, required File image}) async {
    FormData formData =
        FormData.fromMap({'image': await MultipartFile.fromFile(image.path)});

    Response<String> response =
        await dio.post('/companies/' + id + '/image/internal', data: formData);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> updatePublicImage(
      {required String id, required File image}) async {
    FormData formData =
        FormData.fromMap({'image': await MultipartFile.fromFile(image.path)});

    Response<String> response =
        await dio.post('/companies/' + id + '/image/public', data: formData);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> addParticipation(
      {required String id, required bool partner}) async {
    var body = {'partner': partner};

    Response<String> response =
        await dio.post('/companies/' + id + '/participation', data: body);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> updateParticipation(
      {required String id,
      DateTime? confirmed,
      String? member,
      String? notes,
      bool? partner}) async {
    var body = {
      'confirmed': confirmed,
      'member': member,
      'notes': notes,
      'partner': partner
    };

    Response<String> response =
        await dio.put('/companies/' + id + '/participation', data: body);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> addPackage(
      {required String id,
      required List<Item>? items,
      required String name,
      required int price,
      required int vat}) async {
    var body = {
      'items': items?.map((i) => i.toJson()),
      'name': name,
      'price': price,
      'vat': vat
    };

    Response<String> response = await dio
        .post('/companies/' + id + '/participation/package', data: body);
    try {
      return Company.fromJson(json.decode(response.data!));
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
        await dio.get("/companies/" + id + "/participation/status/next");
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

  Future<Company?> updateParticipationStatus(
      {required String id, required ParticipationStatus newStatus}) async {
    Response<String> response = await dio.put(
        "/companies/" + id + "/participation/status/" + newStatus.toString());
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> stepParticipationStatus(
      {required String id, required int step}) async {
    Response<String> response = await dio
        .put("/companies/" + id + "/participation/status/" + step.toString());
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> subscribeToCompany({required String id}) async {
    Response<String> response =
        await dio.put("/companies/" + id + "/subscribe");
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> unsubscribeToSpeaker({required String id}) async {
    Response<String> response =
        await dio.put("/companies/" + id + "/unsubscribe");
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> addThread({
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
        await dio.post("/companies/" + id + "/thread", data: body);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Company?> deleteThread(
      {required String id, required String threadID}) async {
    Response<String> response = await dio
        .delete("/companies/" + id + "/participation/thread/" + threadID);
    try {
      return Company.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
