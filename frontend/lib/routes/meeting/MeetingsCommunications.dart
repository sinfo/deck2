import 'package:flutter/material.dart';
import 'package:frontend/components/threads/threadCard/threadCard.dart';
import 'package:frontend/models/thread.dart';

class MeetingsCommunications extends StatelessWidget {
  final Future<List<Thread>?> communications;
  final bool small;
  final void Function(String) onCommunicationDeleted;

  MeetingsCommunications(
      {Key? key,
      required this.communications,
      required this.small,
      required this.onCommunicationDeleted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
        future: communications,
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
            return ListView(controller: ScrollController(), children: [
              ...threads
                  .map(
                    (thread) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ThreadCard(
                        thread: thread,
                        small: small,
                        onCommunicationDeleted: onCommunicationDeleted,
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