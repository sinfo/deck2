import 'dart:convert';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';
import 'package:frontend/components/deckException.dart';
import 'dart:io';

class FlightInfoService extends Service {
  Future<FlightInfo> getFlightInfo(String id) async {
    Response<String> response = await dio.get("/flightInfo/" + id);
    try {
      return FlightInfo.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<FlightInfo> updateFlightInfo(
      String id,
      DateTime inbound,
      DateTime outbound,
      String from,
      String to,
      String link,
      bool bought,
      int cost,
      String notes) async {
    var body = {
      'inbound': inbound.toIso8601String(),
      'outbound': outbound.toIso8601String(),
      'from': from,
      'to': to,
      'link': link,
      'bought': bought,
      'cost': cost,
      'notes': notes
    };

    Response<String> response = await dio.put("/flightInfo/" + id, data: body);
    try {
      return FlightInfo.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
