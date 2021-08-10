import 'dart:convert';

import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';

class Post {
  final String id;
  final String memberId;
  Member? _member;
  final String? text;
  final DateTime posted;
  final DateTime updated;

  Post({
    required this.id,
    required this.memberId,
    this.text,
    required this.posted,
    required this.updated,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      memberId: json['member'],
      text: json['text'],
      posted: DateTime.parse(json['posted']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Future<void> loadMember() async {
    if (_member == null){
      MemberService memberService = MemberService();
      _member = await memberService.getMember(memberId);
    }
  }

  Member get member {
    if (_member == null){
      throw StateError('Member needs to be loaded before it is accessed');
    }
    return _member!;
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'posted': posted,
        'updated': updated,
        'member': memberId
      };
}
