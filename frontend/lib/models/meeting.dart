import 'dart:convert';

import 'package:frontend/models/thread.dart';
import 'package:frontend/services/threadService.dart';

class Meeting {
  final String id;
  final DateTime begin;
  final DateTime end;
  final String place;
  final String title;
  final String kind;
  final List<String> communicationsId;
  final String? minute;
  final MeetingParticipants participants;
  List<Thread>? _communications;

  Future<List<Thread>?> get communications async {
    ThreadService _threadService = ThreadService();

    if (communicationsId.isEmpty) {
      return [];
    }

    if (_communications != null && _communications!.length != 0) {
      return _communications;
    }

    List<Thread> l = [];
    for (String element in communicationsId) {
      Thread? t = await _threadService.getThread(element);
      if (t != null) {
        l.add(t);
      }
    }

    _communications = l;
    return _communications;
  }

  Meeting(
      {required this.id,
      required this.begin,
      required this.end,
      required this.place,
      required this.title,
      required this.kind,
      required this.communicationsId,
      this.minute,
      required this.participants});

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
        id: json['id'],
        begin: DateTime.parse(json['begin']),
        end: DateTime.parse(json['end']),
        place: json['place'],
        minute: json['minute'],
        title: json['title'],
        kind: json['kind'],
        communicationsId: List.from(json['communications']),
        participants: MeetingParticipants.fromJson(json['participants']));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'begin': begin,
        'end': end,
        'place': place,
        'minute': minute,
        'title': title,
        'kind': kind,
        'communications': communicationsId,
        'participants': participants.toJson()
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class MeetingParticipants {
  final List<String>? membersIds;
  final List<String>? companyRepIds;

  MeetingParticipants({this.membersIds, this.companyRepIds});

  factory MeetingParticipants.fromJson(Map<String, dynamic> json) {
    return MeetingParticipants(
        membersIds: List.from(json['members']),
        companyRepIds: List.from(json['companyReps']));
  }

  Map<String, dynamic> toJson() =>
      {'members': membersIds, 'companyReps': companyRepIds};

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
