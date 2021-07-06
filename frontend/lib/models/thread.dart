import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/post.dart';

class Thread {
  final String id;
  final Post entry;
  final Meeting meeting;
  final List<Post> comments;
  final String kind;
  final String status;

  Thread({
    this.id,
    this.entry,
    this.meeting,
    this.comments,
    this.kind,
    this.status,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    var posts = json['comments'] as List;
    return Thread(
      id: json['id'],
      entry: Post.fromJson(json['entry']),
      meeting: Meeting.fromJson(json['meeting']),
      comments: posts.map((e) => Post.fromJson(e)).toList(),
      kind: json['kind'],
      status: json['status'],
    );
  }
}
