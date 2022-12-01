import 'package:flutter/material.dart';
import 'package:frontend/components/threads/threadCard/threadCard.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/thread.dart';

class ParticipationThreadsWidget extends StatelessWidget {
  final Participation participation;
  final bool small;
  final void Function(String) onCommunicationDeleted;

  ParticipationThreadsWidget(
      {Key? key,
      required this.participation,
      required this.small,
      required this.onCommunicationDeleted})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
