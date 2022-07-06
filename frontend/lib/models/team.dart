import 'dart:convert';

class TeamMember {
  final String? memberID;
  final String? role;

  TeamMember({
    this.memberID,
    this.role,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      memberID: json['member'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
        'member': memberID,
        'role': role,
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class TeamPublic {
  final String? id;
  final String? name;
  final List<TeamMember>? members;

  TeamPublic({this.id, this.name, this.members});

  factory TeamPublic.fromJson(Map<String, dynamic> json) {
    var members = json['members'] as List;
    return TeamPublic(
      id: json['id'],
      name: json['name'],
      members: members.map((e) => TeamMember.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': jsonEncode(members),
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}

class Team {
  final String? id;
  final String? name;
  final List<TeamMember>? members;
  final List<String>? meetings;

  Team({this.id, this.name, this.members, this.meetings});

  factory Team.fromJson(Map<String, dynamic> json) {
    var members = json['members'] as List;
    var meetings = json['meetings'] as List;

    return Team(
      id: json['id'],
      name: json['name'],
      members: members.map((e) => TeamMember.fromJson(e)).toList(),
      meetings: meetings.length == 0? [] :  meetings as List<String>,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': jsonEncode(members),
        'meetings': jsonEncode(meetings),
      };

  @override
  String toString() {
    return json.encode(this.toJson());
  }
}
