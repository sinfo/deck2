import 'package:flutter/material.dart';
import 'package:frontend/components/threads/threadCard/threadCardBody.dart';
import 'package:frontend/components/threads/threadCard/threadCardHeader.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
import 'package:shimmer/shimmer.dart';

final Map<String, Color> THREADCOLOR = {
  "APPROVED": Colors.green,
  "REVIEWED": Colors.green,
  "PENDING": Colors.yellow,
};

enum CommunicationType { COMPANY, MEETING, SPEAKER }

class ThreadCard extends StatefulWidget {
  Thread thread;
  // ID of the meeting/company/speaker
  final String id;
  final CommunicationType type;
  final bool small;
  ThreadCard(
      {Key? key,
      required this.thread,
      required this.small,
      required this.id,
      required this.type})
      : super(key: key);

  @override
  ThreadCardState createState() => ThreadCardState();
}

class ThreadCardState extends State<ThreadCard>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  Future<void> threadChangedCallback(BuildContext context,
      {Thread? thread}) async {
    setState(() {
      widget.thread = thread!;
    });
  }

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
                      p: p,
                      thread: widget.thread,
                      small: widget.small,
                      id: widget.id,
                      type: widget.type,
                      onEditThread: (context, _thread) {
                        threadChangedCallback(context, thread: _thread);
                      }),
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
