import 'package:flutter/material.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/threadService.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

final Map<String, Color> THREADCOLOR = {
  "APPROVED": Colors.green,
  "REVIEWED": Colors.green,
  "PENDING": Colors.yellow,
};

class CommunicationsList extends StatelessWidget {
  final List<Participation> participations;
  final bool small;

  CommunicationsList(
      {Key? key, required this.participations, required this.small})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: ListView(
            controller: ScrollController(),
            children: participations.reversed
                .where((element) =>
                    element.communicationsId != null &&
                    element.communicationsId!.length != 0)
                .map(
                  (participation) => ParticipationThreadsWidget(
                    participation: participation,
                    small: small,
                  ),
                )
                .toList()),
      );
    });
  }
}

class ParticipationThreadsWidget extends StatelessWidget {
  final Participation participation;
  final bool small;

  ParticipationThreadsWidget(
      {Key? key, required this.participation, required this.small})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Getting ${participation.event}');
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
        future: participation.communications,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error');
          }
          if (snapshot.connectionState == ConnectionState.done) {
            List<Thread>? threads = snapshot.data as List<Thread>?;
            if (threads == null) {
              threads = [];
            }
            threads.sort((a, b) => b.posted.compareTo(a.posted));
            return Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('SINFO ${participation.event}'),
                ),
              ),
              Divider(),
              ...threads
                  .map(
                    (thread) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ThreadCard(
                        thread: thread,
                        small: small,
                      ),
                    ),
                  )
                  .toList(),
            ]);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

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
    print(widget.thread.posted.toString());
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
                  SizedBox(
                    height: 16,
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
            Member? me = Provider.of<Member?>(context);
            bool owner = me != null && m.id == me.id;
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: TextStyle(fontSize: small ? 12 : 20),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(thread.posted),
                            style: TextStyle(fontSize: small ? 10 : 14),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // TODO: Implement edit and delete thread
                    // if (owner)
                    //   Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: IconButton(
                    //         onPressed: () {}, icon: Icon(Icons.delete)),
                    //   ),
                    // if (owner)
                    //   Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: IconButton(
                    //         onPressed: () {}, icon: Icon(Icons.edit)),
                    //   ),
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
                            child: CommentStrip(post: e!),
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
                              DateFormat('dd/MM/yyyy').format(post.posted),
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (owner)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.delete),
                            iconSize: 18,
                          ),
                        ),
                      if (owner)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 4.0, 0),
                          child: IconButton(
                            onPressed: () {},
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
              post.text ?? '',
              style: TextStyle(fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
