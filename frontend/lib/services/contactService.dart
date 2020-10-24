import 'dart:convert';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class ContactService extends Service {
  Future<List<Contact>> getContacts({String phone, String mail}) async {
    var queryParameters = {
      "phone": phone,
      "mail": mail,
    };

    Response<String> response =
        await dio.get("/contacts", queryParameters: queryParameters);

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.data) as List;
      return responseJson.map((e) => Contact.fromJson(e)).toList();
    } else {
      // TODO: Handle Error
      print("error");
      return [];
    }
  }

  Future<Contact> getContact(String id) async {
    Response<String> response = await dio.get("/contacts/" + id);
    if (response.statusCode == 200) {
      return Contact.fromJson(json.decode(response.data));
    } else {
      // TODO: Handle Error
      print("error");
      return null;
    }
  }

  Future<Contact> updateContact(Contact contact) async {
    var body = {
      "mails": json.encode(contact.mails),
      "phones": json.encode(contact.phones),
      "socials": json.encode(contact.socials),
    };

    Response<String> response =
        await dio.put("/contacts/" + contact.id, data: body);
    if (response.statusCode == 200) {
      return Contact.fromJson(json.decode(response.data));
    } else {
      // TODO: Handle Error
      print("error");
      return null;
    }
  }
}
