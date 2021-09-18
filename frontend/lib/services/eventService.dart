import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/services/service.dart';

class EventService extends Service {
  final String basePath = '/events';

  Future<Event> getLatestEvent() async {
    try {
      Response<String> res = await dio.get(basePath + "/latest");

      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Lists events, filtered by name, before, during and after dates.
  Future<List<Event>> getEvents({
    String? name,
    DateTime? before,
    DateTime? after,
    DateTime? during,
  }) async {
    var queryParams = {
      'name': name,
      'before': before != null ? before.toIso8601String() : null,
      'after': after != null ? after.toIso8601String() : null,
      'during': during != null ? during.toIso8601String() : null,
    };

    Response<String> response =
        await dio.get(basePath, queryParameters: queryParams);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<Event> events = responseJson.map((e) => Event.fromJson(e)).toList();

      return events;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<List<int>> getEventIds() async {
    try {
      Response<String> response = await dio.get(basePath);

      final responseJson = json.decode(response.data!) as List;
      List<int> ids = responseJson.map((e) => e['id'] as int).toList();
      ids.sort((a, b) => b.compareTo(a));
      return ids;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Updates the current event's dates and name.
  /// Requires coordinator credentials or higher
  Future<Event> updateEvent({
    DateTime? begin,
    DateTime? end,
    String? name,
  }) async {
    var body = {
      'name': name,
      'begin': begin != null ? begin.toIso8601String() : null,
      'end': end != null ? end.toIso8601String() : null,
    };

    Response<String> res = await dio.put(basePath, data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Creates a new event, with incremental id.
  /// Requires Admin credentials.
  Future<Event> createEvent({
    required String name,
  }) async {
    var body = {'name': name};

    Response<String> res = await dio.post(basePath, data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Adds an existing item to current event.
  /// Requires coordinator credentials or higher.
  Future<Event> addItemToEvent({
    required String itemId,
  }) async {
    var body = {'item': itemId};

    Response<String> res = await dio.post(basePath + "/items", data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Removes an item from current event.
  /// Requires coordinator credentials or higher.
  Future<Event> removeItemFromEvent({
    required String itemId,
  }) async {
    Response<String> res = await dio.delete(basePath + "/items/$itemId");

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Creates and adds a meeting to current event.
  /// Requires coordinator credentials or higher.
  Future<Event> addMeetingToEvent({
    required DateTime begin,
    required DateTime end,
    required String place,
  }) async {
    var body = {
      'begin': begin.toIso8601String(),
      'end': end.toIso8601String(),
      'place': place,
    };

    Response<String> res = await dio.post(basePath + "/meetings", data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Removes and deletes a meeting from current event.
  /// Requires coordinator credentials or higher.
  Future<Event> removeMeetingFromEvent({
    required String meetingId,
  }) async {
    Response<String> res = await dio.delete(basePath + "/meetings/$meetingId");

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Adds a package to current event.
  /// Requires coordinator credentials or higher.
  Future<Event> addPackageToEvent({
    required String publicName,
    required String template,
  }) async {
    var body = {
      'public_name': publicName,
      'template': template,
    };

    Response<String> res = await dio.post(basePath + "/packages", data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Updated a package linked to current event.
  /// Requires coordinator credentials or higher.
  Future<Event> updatePackageInEvent({
    required String publicName,
    required String template,
    required bool available,
  }) async {
    var body = {
      'public_name': publicName,
      'available': available,
    };

    Response<String> res =
        await dio.put(basePath + "/packages/$template", data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Removes a package from current event.
  /// Requires coordinator credentials or higher.
  Future<Event> removePackageFromEvent({
    required String template,
  }) async {
    Response<String> res = await dio.delete(basePath + "/packages/$template");

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Creates and adds a session to current event.
  /// Requires coordinator credentials or higher.
  Future<Event> addSessionToEvent(Session s) async {
    var body = {
      'begin': s.begin.toIso8601String(),
      'end': s.end.toIso8601String(),
      'description': s.description,
      'kind': s.kind,
      'title': s.title,
      'place': s.place,
    };

    if (s.kind == 'TALK') {
      body['speaker'] = json.encode(s.speakersIds);
    } else {
      body['company'] = s.companyId;
    }
    Response<String> res = await dio.post(basePath + "/sessions", data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Removes a package from current event.
  /// Requires coordinator credentials or higher.
  Future<Event> updateThemesinEvent({
    required List<String> themes,
  }) async {
    var body = {
      'themes': json.encode(themes),
    };

    Response<String> res = await dio.put(basePath + "/themes", data: body);

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Updates themes in current event.
  /// Requires admin credentials.
  Future<Event> removeTeamFromEvent({
    required String teamId,
  }) async {
    Response<String> res = await dio.delete(basePath + "/teams/$teamId");

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Fetches an event by ID
  Future<Event> getEvent({
    required int eventId,
  }) async {
    Response<String> res = await dio.get(basePath + "/$eventId");

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Deletes an event.
  /// Requires admin credentials.
  Future<Event> deleteEvent({
    required String eventId,
  }) async {
    Response<String> res = await dio.delete(basePath + "/$eventId");

    try {
      return Event.fromJson(json.decode(res.data!));
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  /// Lists events, filtered by name, before, during and after dates.
  Future<List<EventPublic>> getEventsPublic({
    bool? current,
    bool? past,
  }) async {
    var queryParams = {
      'current': current,
      'pastEvents': past,
    };

    Response<String> response =
        await dio.get('/public' + basePath, queryParameters: queryParams);

    try {
      final responseJson = json.decode(response.data!) as List;
      List<EventPublic> events =
          responseJson.map((e) => EventPublic.fromJson(e)).toList();

      return events;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
