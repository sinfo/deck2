import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/postService.dart';
import 'package:frontend/services/threadService.dart';
import 'package:shimmer/shimmer.dart';

final Map<String, Color> THREADCOLOR = {
  "APPROVED": Colors.green,
  "REVIEWED": Colors.green,
  "PENDING": Colors.yellow,
};

class ThreadCard extends StatefulWidget {
  final Thread thread;
  final bool small;
  const ThreadCard({
    Key? key,
    required this.thread,
    required this.small,
  }) : super(key: key);

  @override
  ThreadCardState createState() => ThreadCardState();
}

class ThreadCardState extends State<ThreadCard>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: widget.thread.entry,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }
          Post p = snapshot.data as Post;
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ThreadCardHeader(
                      p: p, thread: widget.thread, small: widget.small),
                  Divider(
                    thickness: 2,
                    color: Colors.grey[600],
                  ),
                  ThreadCardBody(
                    thread: widget.thread,
                    post: p,
                    small: widget.small,
                  )
                ],
              ),
            ),
          );
        } else {
          return Shimmer.fromColors(
            baseColor: Colors.grey[400]!,
            highlightColor: Colors.white,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(5),
              ),
              height: 135,
            ),
          );
        }
      },
    );
  }
}

class ThreadCardHeader extends StatelessWidget {
  final Post p;
  final Thread thread;
  final bool small;
  const ThreadCardHeader({
    Key? key,
    required this.p,
    required this.thread,
    required this.small,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: p.member,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Row(
              children: [],
            );
          }
          Member? m = snapshot.data as Member?;
          if (m != null) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      child: Image.network(
                        m.image!,
                        width: small ? 40 : 50,
                        height: small ? 40 : 50,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/noImage.png',
                            width: small ? 40 : 50,
                            height: small ? 40 : 50,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(small ? 4.0 : 8.0),
                      child: Text(
                        m.name,
                        style: TextStyle(fontSize: small ? 12 : 16),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        thread.kind,
                        style: TextStyle(fontSize: small ? 12 : 16),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: THREADCOLOR[thread.status],
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: EdgeInsets.all(small ? 4.0 : 8.0),
                        child: Text(
                          thread.status,
                          style: TextStyle(fontSize: small ? 12 : 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
}

class ThreadCardBody extends StatefulWidget {
  final Thread thread;
  final Post post;
  final bool small;
  ThreadCardBody(
      {Key? key, required this.thread, required this.post, required this.small})
      : super(key: key);

  @override
  _ThreadCardBodyState createState() => _ThreadCardBodyState();
}

class _ThreadCardBodyState extends State<ThreadCardBody> {
  late Future<Post?> _post;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _post = widget.thread.entry;
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.thread.commentIds.length != 0) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton(
          child: _expanded
              ? Text('See less')
              : Text('${widget.thread.commentIds.length} comments'),
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'No comments yet',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
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
              children: comments
                  .map((e) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CommentStrip(post: e!),
                      ))
                  .toList(),
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.post.text ?? ''),
          Align(
            alignment: Alignment.bottomRight,
            child: _buildFooter(context),
          ),
        ],
      ),
      secondChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.post.text ?? ''),
          Padding(
            padding: EdgeInsets.all(widget.small ? 4.0 : 8.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  VerticalDivider(
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

class CommentStrip extends StatelessWidget {
  final Post post;
  const CommentStrip({Key? key, required this.post}) : super(key: key);

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder(
      future: post.member,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Row(
              children: [],
            );
          }
          Member? m = snapshot.data as Member?;
          if (m != null) {
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
                        child: Text(m.name),
                      )
                    ],
                  ),
                  Divider(
                    thickness: 2,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Text(
            post.text ?? '',
          ),
        ],
      ),
    );
  }
}
