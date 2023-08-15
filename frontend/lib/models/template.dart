
import 'package:frontend/models/requirement.dart';

class Template {
  final String id;
  final String name;
  final List<Requirement>? requirements;

  Template({
    required this.id,
    required this.name,
    this.requirements,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    print(json);
     var requirements = json['requirements'] as List;
    return Template(
      id: json['id'],
      name: json['name'],
      requirements: requirements.map((req) => Requirement.fromJson(req)).toList(),
    );
  }

  String templateAsString() {
    return this.name;
  }

  bool operator ==(o) => o is Template && id == o.id;
  int get hashCode => id.hashCode;
}
