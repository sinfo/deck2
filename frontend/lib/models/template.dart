
import 'package:frontend/models/requirement.dart';

class Template {
  final String id;
  final String name;
  final List<Requirement>? requirements;
  final String kind;

  Template({
    required this.id,
    required this.name,
    this.requirements,
    required this.kind,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
     var requirements = json['requirements'] as List;
    return Template(
      id: json['id'],
      name: json['name'],
      requirements: requirements.map((req) => Requirement.fromJson(req)).toList(),
      kind: json['kind'],
    );
  }

  String templateAsString() {
    return this.name;
  }

  bool operator ==(o) => o is Template && id == o.id;
  int get hashCode => id.hashCode;
}
