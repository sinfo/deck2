import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/services/service.dart';

class PackageService extends Service {
  final String baseURL = '/packages';

  Future<List<Package>> getPackages(
      {String? name, int? price, int? vat}) async {
    var queryParameters = {
      "name": name,
      "price": price,
      "vat": vat,
    };

    Response<String> response =
        await dio.get(baseURL, queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Package> packages =
          responseJson.map((e) => Package.fromJson(e)).toList();
      return packages;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Package?> createPackage(
      {List<PackageItem>? items,
      required String name,
      required int price,
      required int vat}) async {
    var body = {
      "items": items == null ? null : items.map((i) => i.toJson()).toList(),
      "name": name,
      "price": price,
      "vat": vat,
    };

    print(body);

    Response<String> response = await dio.post(baseURL, data: body);

    try {
      return Package.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Package?> getPackage(String id) async {
    Response<String> response = await dio.get(baseURL + '/$id');

    try {
      return Package.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Package?> updatePackage(
      String id, String name, int price, int vat) async {
    var body = {
      "name": name,
      "price": price,
      "vat": vat,
    };

    Response<String> response = await dio.put(baseURL + '/$id', data: body);

    try {
      return Package.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Package?> updatePackageItems(String id, List<Item> package) async {
    var body = {"package": jsonEncode(package)};

    Response<String> response = await dio.put(baseURL + '/$id', data: body);

    try {
      return Package.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
