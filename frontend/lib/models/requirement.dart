
class Requirement {
  final String title;
  final String name;
  final String type;
  String? stringVal;
  int? intVal;
  bool? boolVal;
  DateTime? dateVal;

  Requirement({
    required this.title,
    required this.name,
    required this.type,
    this.stringVal,
    this.intVal,
    this.boolVal,
    this.dateVal,
  });

  factory Requirement.fromJson(Map<String, dynamic> json) {
    return Requirement(
      title: json['title'],
      name: json['name'],
      type: json['type'],
      stringVal: json['stringVal'],
      intVal: json['intVal'],
      boolVal: json['boolVal'],
      dateVal: DateTime.parse(json['dateVal']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'name': name,
        'type': type,
        'stringVal': stringVal,
        'intVal': intVal,
        'boolVal': boolVal,
        'dateVal': dateVal?.toIso8601String(),
      };

  String RequirementAsString() {
    return '${this.title}';
  }
}
