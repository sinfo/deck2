import 'dart:convert';

import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';

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
  final List<TeamMember>? membersID;
  List<Member?>? _members;
  final List<String>? meetings;
  final MemberService _memberService = MemberService();


  Team({this.id, this.name, this.membersID, this.meetings});

  factory Team.fromJson(Map<String, dynamic> json) {
    var members = json['members'] as List;
    var meetings = json['meetings'] as List;

    return Team(
      id: json['id'],
      name: json['name'],
      membersID: members.map((e) => TeamMember.fromJson(e)).toList(),
      meetings: meetings.length == 0 ? [] : meetings as List<String>,
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

  Future<List<Member?>> get members async {
    if (_members != null) {
      return _members!;
    }
    _members = await Future.wait(
        membersID!.map((m) async => await _memberService.getMember(m.memberID!)).toList());

    return _members!;

  }
}
