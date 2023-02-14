import 'dart:convert';
import 'dart:io';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class ItemService extends Service{

  //getItems
  Future<List<Item>> getItems({String? name, String? type}) async {
    var queryParameters = {
      'name': name,
      'type': type,
    };

    Response<String> response =
        await dio.get("/items", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Item> items =
          responseJson.map((e) => Item.fromJson(e)).toList();
      return items;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Item?> getItem(String id) async {
    Response<String> response = await dio.get('/items/$id');

    if (response.statusCode == 200) {
      return Item.fromJson(json.decode(response.data!));
    } else {
      return null;
    }
  }

  Future<Item?> createItem(String name, String type, String description, int price, int vat) async {
    var body = {
      'name': name,
      'type': type,
      'description': description,
      'price': price,
      'vat': vat, 
    };

    Response<String> response = await dio.post("/items", data: body);

    try {
      return Item.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }


  Future<Item?> updateItem(String id, String name, String type, String description, int price, int vat) async {
    var body = {
      'name': name,
      'type': type,
      'description': description,
      'price': price,
      'vat': vat, 
    };

    Response<String> response = await dio.put("/items/$id", data: body);

    try {
      return Item.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Item?> deleteItem(String id) async {
    Response<String> response = await dio.delete("/items/" + id);
    try {
      return Item.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }


  //  FIXME: não tenho a certeza se se faz assim
  Future<Item?> uploadItemImage(String id, String url) async {
    var body = {
      'img': url 
    };

    Response<String> response = await dio.put("/items/$id", data: body);

    try {
      return Item.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

}