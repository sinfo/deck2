
class Requirement {
  final String title;
  final String name;
  final String type;
  String? stringVal;
  bool? boolVal;

  Requirement({
    required this.title,
    required this.name,
    required this.type,
    this.stringVal,
    this.boolVal,
  });

  factory Requirement.fromJson(Map<String, dynamic> json) {
    return Requirement(
      title: json['title'],
      name: json['name'],
      type: json['type'],
      stringVal: json['stringVal'],
      boolVal: json['boolVal'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'name': name,
        'type': type,
        'stringVal': stringVal,
        'boolVal': boolVal,
      };

  String RequirementAsString() {
    return '${this.title}';
  }
}
