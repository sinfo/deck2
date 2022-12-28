import 'dart:convert';
import 'dart:io';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class BillingService extends Service {
  Future<List<Billing>> getBillings({int? event, String? company}) async {
    var queryParameters = {
      'company': company,
      'event': event,
    };

    Response<String> response =
        await dio.get("/billings", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Billing> billings =
          responseJson.map((e) => Billing.fromJson(e)).toList();
      return billings;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Billing?> getBilling(String id) async {
    Response<String> response = await dio.get('/billings/$id');

    if (response.statusCode == 200) {
      return Billing.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<Billing?> updateBilling(Billing billing) async {
    var body = billing.toJson();

    Response<String> response = await dio.put('/billings/${billing.id}', data: body);

    try {
      return Billing.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
