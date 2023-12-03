import 'dart:convert';

class FlightInfo {
  final String id;
  final int event;
  final String speaker;
  final DateTime inbound;
  final DateTime outbound;
  final String from;
  final String to;
  final String link;
  final bool bought;
  final int cost;
  final String notes;

  FlightInfo(
      {required this.id,
      required this.event,
      required this.speaker,
      required this.inbound,
      required this.outbound,
      required this.from,
      required this.to,
      required this.link,
      required this.bought,
      required this.cost,
      required this.notes});

  factory FlightInfo.fromJson(Map<String, dynamic> json) {
    return FlightInfo(
      id: json['id'],
      event: json['event'],
      speaker: json['speaker'],
      inbound: DateTime.parse(json['inbound']),
      outbound: DateTime.parse(json['outbound']),
      from: json['from'],
      to: json['to'],
      link: json['link'],
      bought: json['bought'],
      cost: json['cost'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event': event,
        'speaker': speaker,
        'inbound': inbound,
        'outbound': outbound,
        'from': from,
        'to': to,
        'link': link,
        'bought': bought,
        'cost': cost,
        'notes': notes
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
