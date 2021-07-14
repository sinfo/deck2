import 'dart:convert';
import 'dart:io';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';


class BillingService extends Service{

    Future<List<Billing>> getBillings({int? event, String? company}) async{
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

    
    //FIXME: não tenho a certeza sobre o BillingStatus
    Future<Billing?> createBilling(String id, BillingStatus status, int event, String company, int value, String invoiceNumber, DateTime emission, String notes, bool visible) async{
      var body = {
        'id': id,
        'status': status,
        'event': event,
        'company': company,
        'value': value,
        'invoiceNumber': invoiceNumber,
        'emission': emission,
        'notes': notes,
        'visible': visible,
      };

      Response<String> response = await dio.post("/billings", data: body);

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


    Future<Billing?> updateMember(String id, BillingStatus status, int event, String company, int value, String invoiceNumber, DateTime emission, String notes, bool visible) async {
      var body = {
          'status': status,
          'event': event,
          'company': company,
          'value': value,
          'invoiceNumber': invoiceNumber,
          'emission': emission,
          'notes': notes,
          'visible': visible,
      };

      Response<String> response = await dio.put('/billings/$id', data: body);

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
    

    
    Future<Billing?> deleteBilling(String id) async {
      Response<String> response = await dio.delete('/billings/$id');
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