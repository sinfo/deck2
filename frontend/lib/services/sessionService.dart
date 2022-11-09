import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/services/service.dart';
import 'package:frontend/components/deckException.dart';

import '../models/event.dart';

class SessionService extends Service {
  Future<List<Session>> getSessions(
      {int? event, String? company, String? kind}) async {
    var queryParameters = {'event': event, 'company': company, 'kind': kind};

    Response<String> response =
        await dio.get("/sessions", queryParameters: queryParameters);

    try {
      final responseJson = json.decode(response.data!) as List;

      List<Session> sessions =
          responseJson.map((e) => Session.fromJson(e)).toList();
      return sessions;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Session> getSession(String id) async {
    Response<String> response = await dio.get('/sessions/$id');

    try {
      return Session.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Session> createSession(
      DateTime begin,
      DateTime end,
      String place,
      String kind,
      String title,
      String description,
      List<String>? speakersIds,
      String? company,
      String? videoURL,
      SessionTickets sessionTickets) async {
    var body = kind == "Talk"
        ? {
            "begin": begin.toIso8601String(),
            "end": end.toIso8601String(),
            "place": place,
            "title": title,
            "kind": kind.toUpperCase(),
            "description": description,
            "speaker": speakersIds,
            "videoURL": videoURL,
            // "tickets": sessionTickets.toJson(),
            "company": ""
          }
        : {
            "begin": begin.toIso8601String(),
            "end": end.toIso8601String(),
            "place": place,
            "title": title,
            "kind": kind.toUpperCase(),
            "description": description,
            "speaker": [],
            "company": company,
            "videoURL": videoURL,
            // "tickets": sessionTickets.max == 0 ? null : sessionTickets.toJson()
          };

    if (sessionTickets.max != 0) {
      body["tickets"] = sessionTickets.toJson();
    }

    Response<String> response = await dio.post("/events/sessions", data: body);

    try {
      int eventId = Event.fromJson(json.decode(response.data!)).id;
      print("Event id " + eventId.toString());
      Future<List<Session>> _futureSessions = getSessions(event: eventId);
      List<Session> sessions = await _futureSessions;
      Session s = sessions.last;

      return s;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Session> deleteSession(String id) async {
    Response<String> response = await dio.delete("/sessions/" + id);
    try {
      return Session.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Session> updateSession(Session session) async {
    var body = session.toJson();

    Response<String> response =
        await dio.put('/sessions/${session.id}', data: body);

    try {
      return Session.fromJson(json.decode(response.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
