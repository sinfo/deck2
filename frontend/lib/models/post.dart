import 'package:frontend/models/member.dart';

class Post {
  final String? id;
  final Member? member;
  final String? text;
  final DateTime? posted;
  final DateTime? updated;

  Post({
    this.id,
    this.member,
    this.text,
    this.posted,
    this.updated,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      member: Member.fromJson(json['member']),
      text: json['text'],
      posted: DateTime(json['posted']),
      updated: DateTime(json['updated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'member': member?.toJson(),
    'text': text,
    'posted': posted,
    'updated': updated
  };
}
