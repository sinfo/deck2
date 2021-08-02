import 'dart:convert';

class CompanyRep {
  final String? id;
  final String? name;
  final String? contactId;

  CompanyRep({
    this.id,
    this.name,
    this.contactId,
  });

  factory CompanyRep.fromJson(Map<String, dynamic> json) {
    return CompanyRep(
      id: json['id'],
      name: json['name'],
      contactId: json['contact'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contact': contactId,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
