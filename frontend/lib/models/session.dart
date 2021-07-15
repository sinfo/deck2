import 'dart:convert';

//import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/company.dart';

class Session {
  final String? id;
  final DateTime? begin;
  final DateTime? end;
  final String? title;
  final String? description;
  final String? place;
  final String? kind;
  final Company? company;
  //final List<Speaker>? speakers;
  final String? videoURL;
  final SessionTickets? tickets;

  Session({
    this.id,
    this.begin,
    this.end,
    this.title,
    this.description,
    this.place,
    this.kind,
    this.company,
    //this.speakers,
    this.videoURL,
    this.tickets,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    //var speaker = json['speaker'] as List;
    return Session(
      id: json['id'],
      begin: DateTime(json['begin']),
      end: DateTime(json['end']),
      title: json['title'],
      description: json['description'],
      place: json['place'],
      kind: json['kind'],
      company: Company.fromJson(json['company']),
      //speakers: speakers.map((e) => Speaker.fromJson(e)).toList(),
      videoURL: json['videoURL'],
      tickets: SessionTickets.fromJson(json['tickets']),
    );
  }

  /*Map<String, dynamic> toJson() => {
    'id': id,
    'behin': begin,
    'end': end,
    'title': title,
    'description': description,
    'place': place,
    'company': company.toJson(),
  }

  @Override
  String toString() {
    return json.encode(this.toJson());
  }*/
}

class SessionPublic {
  final String? id;
  final DateTime? begin;
  final DateTime? end;
  final String? title;
  final String? description;
  final String? place;
  final String? kind;
  final Company? companyPublic;
  //final List<Speaker>? speakersPublic;
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
    this.companyPublic,
    //this.speakersPublic,
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
      companyPublic: Company.fromJson(json['company']),
      //speakersPublic: speakersPublic.map((e) => Speaker.fromJson(e)).toList(),
      videoURL: json['videoURL'],
      tickets: SessionTickets.fromJson(json['tickets']),
    );
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
      start: DateTime(json['start']),
      end: DateTime(json['end']),
      max: json['max'],
    );
  }
}
