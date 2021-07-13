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
      start: DateTime(json['begin']),
      end: DateTime(json['end']),
    );
  }
}
