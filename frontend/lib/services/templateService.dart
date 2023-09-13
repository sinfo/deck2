
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/models/requirement.dart';
import 'package:frontend/models/template.dart';
import 'package:frontend/services/service.dart';
import 'package:frontend/components/deckException.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class TemplateService extends Service {
  
  Future<String?> fillTemplate({required String id, required List<Requirement> filledRequirements}) async {

    var req = filledRequirements.map((e) => e.toJson()).toList();

    var body = {'requirements': req};

    Response<String> response = await dio.post('/templates/fill/' + id, data: body);
    if (response.statusCode == 200) {
      return response.data!;
    } else {
      return null;
    }
  }
  
  Future<Template?> uploadTemplateFile(
      {required String id, required PlatformFile template}) async {
    FormData body;

    if (kIsWeb) {
      Uint8List file = template.bytes!;

      body = FormData.fromMap(
        {
          'template': MultipartFile.fromBytes(
            file,
            filename: template.name,
            contentType: MediaType('multipart', 'form-data'),
          )
        },
      );
    } else {
      body = FormData.fromMap(
          {'template': await MultipartFile.fromFile(template.path!)});
    }

    Response<String> response = await dio.post('/templates/file/' + id, data: body);

    if(response.statusCode != 200) {

    }
    try {
      return Template.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Template?> createTemplate(
      {required String name, required List<Requirement> requirements}) async {

    var req = requirements.map((e) => e.toJson()).toList();

    var body = {'requirements': req};

    Response<String> response = await dio.post('/templates/' + name, data: body);

    if(response.statusCode != 200) {

    }
    try {
      return Template.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<List<Template>> getTemplates(
      {int? event}) async {
    Map<String, dynamic> queryParams = {};
    if (event != null) {
      queryParams['event'] = event;
    }

    String templateUrl = '/templates';
    Response<String> res =
        await dio.get(templateUrl, queryParameters: queryParams);

    try {
      final responseJson = json.decode(res.data!) as List;
      List<Template> templates =
          responseJson.map((e) => Template.fromJson(e)).toList();
      return templates;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
