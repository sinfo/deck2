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
  late List<Post?> _comments; 
  final String kind;
  final String status;
  final PostService _postService = PostService();
  final MeetingService _meetingService = MeetingService();

  Thread({
    required this.id,
    required this.entryid,
    this.meetingId,
    required this.commentIds,
    required this.kind,
    required this.status,
  }){
    print('Thread created with:');
    print('id: $id');
    print('entry: $entry');
    print('comments: $commentIds');
    print('kind: $kind');
    print('status: $status');
    _comments = List<Post?>.filled(commentIds.length, null);
  }

  factory Thread.fromJson(Map<String, dynamic> json) {
    print(json);
    List<String> commentIds = List.from( json['comments'] );
 
    var thread = Thread(
      id: json['id'],
      entryid: json['entry'],
      meetingId: json['meeting'],
      commentIds: commentIds,
      kind: json['kind'],
      status: json['status'],
    );
    print(thread);
    return thread;
  }

  Future<Post?> get entry async {
    if (_entry != null){
      return _entry!;
    }
    _entry = await _postService.getPost(entryid);
    return _entry;
  }

  Future<Post?> getComment(int index) async{
    if (index >= _comments.length) {
      throw RangeError('index out of range');
    }
    if (_comments[index] == null){
      _comments[index] = await _postService.getPost(commentIds[index]); //TODO, getPost might return null
    }
    return _comments[index];
  }

  bool get hasMeeting {
    return meetingId != null;
  }
  
  Future<Meeting?> get meeting async{
    if (_meeting != null){
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
