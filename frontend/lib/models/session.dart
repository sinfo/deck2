import 'dart:convert';

class Session {
  final String id;
  final DateTime begin;
  final DateTime end;
  final String title;
  final String description;
  final String? place;
  final String kind;
  final String? companyId;
  final List<String>? speakersIds;
  final String? videoURL;
  final SessionTickets? tickets;

  Session({
    required this.id,
    required this.begin,
    required this.end,
    required this.title,
    required this.description,
    this.place,
    required this.kind,
    this.companyId,
    this.speakersIds,
    this.videoURL,
    this.tickets,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      begin: DateTime.parse(json['begin']),
      end: DateTime.parse(json['end']),
      title: json['title'],
      description: json['description'],
      place: json['place'],
      kind: json['kind'],
      companyId: json['company'],
      speakersIds: List.from(json['speaker']),
      videoURL: json['videoURL'],
      tickets: json['tickets'] == null
          ? null
          : SessionTickets.fromJson(json['tickets']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'begin': begin.toIso8601String(),
        'end': end.toIso8601String(),
        'title': title,
        'description': description,
        'place': place,
        'kind': kind,
        'company': companyId,
        'speaker': speakersIds,
        'videoURL': videoURL,
        'tickets': tickets?.toJson(),
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class SessionPublic {
  final String? id;
  final DateTime? begin;
  final DateTime? end;
  final String? title;
  final String? description;
  final String? place;
  final String? kind;
  final String? companyPublicId;
  final List<String>? speakersPublicIds;
  final String? videoURL;
  final SessionTickets? tickets;

  SessionPublic({
    this.id,
    this.begin,
    this.end,
    this.title,
    this.description,
    this.place,
    this.kind,
    this.companyPublicId,
    this.speakersPublicIds,
    this.videoURL,
    this.tickets,
  });

  factory SessionPublic.fromJson(Map<String, dynamic> json) {
    return SessionPublic(
      id: json['id'],
      begin: DateTime(json['begin']),
      end: DateTime(json['end']),
      title: json['title'],
      description: json['description'],
      place: json['place'],
      kind: json['kind'],
      companyPublicId: json['company'],
      speakersPublicIds: json['speaker'],
      videoURL: json['videoURL'],
      tickets: SessionTickets.fromJson(json['tickets']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'begin': begin,
        'end': end,
        'title': title,
        'description': description,
        'place': place,
        'kind': kind,
        'company': companyPublicId,
        'speaker': speakersPublicIds,
        'videoURL': videoURL,
        'tickets': tickets?.toJson(),
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class SessionTickets {
  final DateTime? start;
  final DateTime? end;
  final int? max;

  SessionTickets({
    this.start,
    this.end,
    this.max,
  });

  factory SessionTickets.fromJson(Map<String, dynamic> json) {
    return SessionTickets(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      max: json['max'],
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start?.toUtc().toIso8601String(),
        'end': end?.toUtc().toIso8601String(),
        'max': max,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
