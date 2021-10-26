import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/services/postService.dart';
import 'package:frontend/services/meetingService.dart';

class Thread {
  final String id;
  final String entryid;
  Post? _entry;
  final String? meetingId;
  Meeting? _meeting;
  final List<String> commentIds;
  List<Post?>? _comments;
  final String kind;
  final String status;
  final PostService _postService = PostService();
  final MeetingService _meetingService = MeetingService();
  final DateTime posted;

  Thread(
      {required this.id,
      required this.entryid,
      this.meetingId,
      required this.commentIds,
      required this.kind,
      required this.status,
      required this.posted}) {}

  factory Thread.fromJson(Map<String, dynamic> json) {
    List<String> commentIds = List.from(json['comments']);

    var thread = Thread(
      id: json['id'],
      entryid: json['entry'],
      meetingId: json['meeting'],
      commentIds: commentIds,
      kind: json['kind'],
      status: json['status'],
      posted: DateTime.parse(json['posted']),
    );
    return thread;
  }

  Future<Post?> get entry async {
    if (_entry != null) {
      return _entry!;
    }
    _entry = await _postService.getPost(entryid);
    return _entry;
  }

  Future<List<Post?>> get comments async {
    if (_comments != null) {
      return _comments!;
    }
    _comments = await Future.wait(
        commentIds.map((e) async => await _postService.getPost(e)).toList());
    return _comments!;
  }

  bool get hasMeeting {
    return meetingId != null;
  }

  Future<Meeting?> get meeting async {
    if (_meeting != null) {
      return _meeting!;
    }
    _meeting = await _meetingService.getMeeting(meetingId!);
    return _meeting;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entry': entry,
        'meeting': meetingId,
        'kind': kind,
        'status': status,
        'comments': commentIds
      };
}
