import 'package:frontend/models/participation.dart';

class Images {
  final String company;
  final String internal;
  final String speaker;

  Images({this.company, this.internal, this.speaker});

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
        company: json['company'],
        internal: json['internal'],
        speaker: json['speaker']);
  }

  Map<String, dynamic> toJson() =>
      {'company': company, 'internal': internal, 'speaker': speaker};
}

class Speaker {
  final String id;
  final String name;
  final String title;
  final String contact;
  final String bio;
  final String notes;
  final Images imgs;
  final List<Participation> participations;

  Speaker(
      {this.id,
      this.name,
      this.title,
      this.contact,
      this.bio,
      this.notes,
      this.imgs,
      this.participations});

  factory Speaker.fromJson(Map<String, dynamic> json) {
    var participationsList = json['participations'] as List;
    return Speaker(
        id: json['id'],
        name: json['name'],
        title: json['title'],
        contact: json['contact'],
        bio: json['bio'],
        notes: json['notes'],
        imgs: Images.fromJson(json['imgs']),
        participations: participationsList
            .map((participation) => Participation.fromJson(participation)));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'contact': contact,
        'bio': bio,
        'notes': notes,
        'imgs': imgs.toJson(),
        'participations':
            participations.map((participation) => participation.toJson())
      };
}
