import 'dart:convert';
import 'dart:io';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class ThreadService extends Service {
  final String baseUrl = '/threads';

  Future<Thread?> addCommentToThread(
    String threadid,
    String text,
  ) async {
    var body = {
      "text": text,
    };

    Response<String> response =
        await dio.post(baseUrl + '/$threadid/comments', data: body);
    try {
      if (response.statusCode == 200) {
        return Thread.fromJson(json.decode(response.data!));
      } else {
        return null;
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Thread?> getThread(String id) async {
    Response<String> response = await dio.get(baseUrl + '/$id');

    try {
      if (response.statusCode == 200) {
        Thread thread = Thread.fromJson(json.decode(response.data!));
        return thread;
      } else {
        return null;
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Thread?> updateThread(String id, String meetingId, String kind) async { //TODO are meetingId or kind nullable?
    var body = {
      "meeting": meetingId,
      "kind": kind,
    };

    Response<String> response = await dio.put(baseUrl + '/$id', data: body);

    try {
      if (response.statusCode == 200) {
        return Thread.fromJson(json.decode(response.data!));
      } else {
        return null;
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Thread?> deleteCommentFromThread(String id, String postid) async {
    Response<String> response =
        await dio.delete(baseUrl + '/$id/comments/$postid');
    try {
      if (response.statusCode == 200) {
        return Thread.fromJson(json.decode(response.data!));
      } else {
        return null;
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
