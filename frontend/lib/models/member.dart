import 'dart:convert';

import 'package:frontend/models/contact.dart';
import 'package:frontend/models/team.dart';

class Member {
  final String id;
  final String name;
  final String? image;
  final String istId;
  final String sinfoId;
  final String? contact;

  Member({
    required this.id,
    required this.name,
    this.image,
    required this.istId,
    required this.sinfoId,
    this.contact,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      image: json['img'],
      istId: json['istid'],
      sinfoId: json['sinfoid'],
      contact: json['contact'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'img': image,
        'istid': istId,
        'sinfoid': sinfoId,
        'contact': contact,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }

  bool operator ==(o) => o is Member && id == o.id;
  int get hashCode => id.hashCode;
}

class MemberPublic {
  final String? name;
  final String? image;
  final ContactSocials? socials;

  MemberPublic({
    this.name,
    this.image,
    this.socials,
  });

  factory MemberPublic.fromJson(Map<String, dynamic> json) {
    return MemberPublic(
      name: json['name'],
      image: json['img'],
      socials: ContactSocials.fromJson(json['socials']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'img': image,
        'socials': socials?.toJson(),
      };
}

class MemberParticipation {
  final int? event;
  final String? role;
  final String? team;

  MemberParticipation({
    this.event,
    this.role,
    this.team,
  });

  factory MemberParticipation.fromJson(Map<String, dynamic> json) {
    return MemberParticipation(
      event: json['event'],
      role: json['role'],
      team: json['team'],
    );
  }

  Map<String, dynamic> toJson() => {
        'event': event,
        'role': role,
        'team': team,
      };
}
