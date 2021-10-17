class Event {
  final int id;
  final String name;
  final DateTime start;
  final DateTime end;

  Event({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      start: DateTime.parse(json['begin']),
      end: DateTime.parse(json['end']),
    );
  }
}

class EventPublic {
  final int id;
  final String name;
  final DateTime start;
  final DateTime end;
  final List<String> themes;

  EventPublic({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.themes,
  });

  factory EventPublic.fromJson(Map<String, dynamic> json) {
    return EventPublic(
      id: json['id'],
      name: json['name'],
      start: DateTime.parse(json['begin']),
      end: DateTime.parse(json['end']),
      themes: json['themes'] as List<String>,
    );
  }
}
