import 'package:flutter/material.dart';
import 'package:frontend/components/threads/commentStrip.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/threadService.dart';
import 'package:shimmer/shimmer.dart';

class ThreadCardBody extends StatefulWidget {
  Thread thread;
  final Post post;
  final bool small;
  ThreadCardBody(
      {Key? key, required this.thread, required this.post, required this.small})
      : super(key: key);

  @override
  _ThreadCardBodyState createState() => _ThreadCardBodyState();
}

class _ThreadCardBodyState extends State<ThreadCardBody> {
  bool _expanded = false;
  late TextEditingController _newCommentController;
  ThreadService _threadService = ThreadService();

  @override
  void initState() {
    super.initState();
    _newCommentController = TextEditingController();
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton(
        child: _expanded
            ? Text('See less')
            : Text(widget.thread.commentIds.length != 0
                ? widget.thread.commentIds.length == 1
                    ? '${widget.thread.commentIds.length} comment'
                    : '${widget.thread.commentIds.length} comments'
                : "Add comment"),
        onPressed: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
      ),
    );
  }

  Future<void> threadChangedCallback(BuildContext context,
      {Future<Thread?>? ft, Thread? thread}) async {
    Thread? t;
    if (ft != null) {
      t = await ft;
    } else if (thread != null) {
      t = thread;
    }
    if (t != null) {
      setState(() {
        widget.thread = t!;
      });
    }
  }

  Widget _buildComments(BuildContext context) {
    return FutureBuilder(
        future: widget.thread.comments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text('err');
            }
            List<Post?> comments = snapshot.data as List<Post?>;
            comments = comments.where((element) => element != null).toList();
            comments.sort((a, b) => a!.posted.compareTo(b!.posted));
            return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...comments
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CommentStrip(
                              post: e!,
                              threadID: widget.thread.id,
                              onEditThread: (context, _thread) {
                                threadChangedCallback(context, thread: _thread);
                              },
                            ),
                          ))
                      .toList(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _newCommentController,
                      decoration: InputDecoration(
                        labelText: 'New comment',
                        disabledBorder: InputBorder.none,
                        suffixIcon: IconButton(
                          onPressed: () async {
                            String comment = _newCommentController.text;
                            if (comment.isNotEmpty) {
                              Thread? t =
                                  await _threadService.addCommentToThread(
                                      widget.thread.id, comment);
                              if (t != null) {
                                setState(() {
                                  widget.thread = t;
                                });
                                _newCommentController.clear();
                              }
                            }
                          },
                          icon: Icon(Icons.add_circle_outline_outlined),
                        ),
                      ),
                    ),
                  ),
                ]);
          } else {
            return Shimmer.fromColors(
                baseColor: Colors.grey[400]!,
                highlightColor: Colors.white,
                child: Column(
                  children:
                      widget.thread.commentIds.map((e) => Container()).toList(),
                ));
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.text ?? '',
            style: TextStyle(fontSize: 16),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _buildFooter(context),
          ),
        ],
      ),
      secondChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post.text ?? '',
            style: TextStyle(fontSize: 16),
          ),
          Padding(
            padding: EdgeInsets.all(widget.small ? 4.0 : 8.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  VerticalDivider(
                    color: Colors.grey,
                    width: 8,
                    thickness: 5,
                  ),
                  Expanded(child: _buildComments(context)),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _buildFooter(context),
          ),
        ],
      ),
      crossFadeState:
          !_expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: Duration(milliseconds: 250),
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeOut,
      sizeCurve: Curves.easeOut,
    );
  }
}
