import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/threads/editPostForm.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/threadService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CommentStrip extends StatefulWidget {
  Post post;
  final String threadID;
  final void Function(BuildContext, Thread?)? onEditThread;

  CommentStrip(
      {Key? key,
      required this.post,
      required this.threadID,
      required this.onEditThread})
      : super(key: key);

  @override
  _CommentStripState createState() => _CommentStripState();
}

class _CommentStripState extends State<CommentStrip> {
  ThreadService _threadService = ThreadService();

  void _deleteCommentThread(context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Deleting', style: TextStyle(color: Colors.white))),
    );

    Thread? t = await _threadService.deleteCommentFromThread(
        widget.threadID, widget.post.id);
    if (t != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Done', style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
        ),
      );

      widget.onEditThread!(context, t);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occured.',
                style: TextStyle(color: Colors.white))),
      );
    }
  }

  void _deleteCommentThreadDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete comment with content ${widget.post.text}?',
            () {
          _deleteCommentThread(context);
        });
      },
    );
  }

  Future<void> postChangedCallback(BuildContext context,
      {Future<Post?>? fp, Post? post}) async {
    Post? p;
    if (fp != null) {
      p = await fp;
    } else if (post != null) {
      p = post;
    }
    if (p != null) {
      setState(() {
        widget.post = p!;
      });
    }
  }

  void _editCommentModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
            child: EditPostForm(
                post: widget.post,
                onEditPost: (context, _post) {
                  postChangedCallback(context, post: _post);
                }));
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder(
      future: widget.post.member,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Row(
              children: [],
            );
          }
          Member? m = snapshot.data as Member?;
          if (m != null) {
            Member? me = Provider.of<Member?>(context);
            bool owner = me != null && m.id == me.id;
            return IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        child: Image.network(
                          m.image!,
                          width: 30,
                          height: 30,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
                            return Image.asset(
                              'assets/noImage.png',
                              width: 30,
                              height: 30,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(widget.post.posted),
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (owner)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
                          child: IconButton(
                            onPressed: () {
                              _deleteCommentThreadDialog(context);
                            },
                            icon: Icon(Icons.delete),
                            iconSize: 18,
                          ),
                        ),
                      if (owner)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 4.0, 0),
                          child: IconButton(
                            onPressed: () {
                              _editCommentModal(context);
                            },
                            icon: Icon(Icons.edit),
                            iconSize: 18,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return Row(
              children: [],
            );
          }
        } else {
          return Row(
            children: [],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Provider.of<ThemeNotifier>(context).isDark
            ? Colors.grey[850]
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(
              height: 16,
            ),
            Text(
              widget.post.text ?? '',
              style: TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
