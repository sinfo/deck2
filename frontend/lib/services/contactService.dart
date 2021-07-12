import 'dart:convert';
import 'dart:io';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class ContactService extends Service {
  Future<List<Contact>> getContacts({String? phone, String? mail}) async {
    var queryParameters = {
      "phone": phone,
      "mail": mail,
    };

    Response<String> response =
        await dio.get("/contacts", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      return responseJson.map((e) => Contact.fromJson(e)).toList();
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Contact?> getContact(String id) async {
    Response<String> response = await dio.get("/contacts/" + id);
    try {
      return Contact.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Contact?> updateContact(Contact contact) async {
    var body = {
      "mails": json.encode(contact.mails),
      "phones": json.encode(contact.phones),
      "socials": json.encode(contact.socials),
    };

    Response<String> response =
        await dio.put("/contacts/" + contact.id!, data: body);
    try {
      return Contact.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
