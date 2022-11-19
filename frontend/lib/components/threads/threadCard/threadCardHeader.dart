import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/threads/editThreadForm.dart';
import 'package:frontend/components/threads/threadCard/threadCard.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ThreadCardHeader extends StatelessWidget {
  final Post p;
  final Thread thread;
  // ID of the meeting/company/speaker
  final String id;
  final CommunicationType type;
  final bool small;
  const ThreadCardHeader(
      {Key? key,
      required this.p,
      required this.thread,
      required this.small,
      required this.id,
      required this.type})
      : super(key: key);

  void _deleteThread(context) async {
    bool isThreadDeleted = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting')),
    );

    if (type == CommunicationType.COMPANY) {
      CompanyService _companyService = CompanyService();
      Company? c =
          await _companyService.deleteThread(id: id, threadID: thread.id);
      if (c != null) {
        // FIXME: notifier not working well
        // CompanyTableNotifier notifier =
        //     Provider.of<CompanyTableNotifier>(context, listen: false);
        // notifier.edit(c);

        isThreadDeleted = true;
      }
    } else if (type == CommunicationType.SPEAKER) {
      SpeakerService _speakerService = SpeakerService();
      Speaker? s =
          await _speakerService.deleteThread(id: id, threadID: thread.id);
      if (s != null) {
        // FIXME: notifier not working well
        // SpeakerTableNotifier notifier =
        //     Provider.of<SpeakerTableNotifier>(context, listen: false);
        // notifier.edit(s);

        isThreadDeleted = true;
      }
    } else if (type == CommunicationType.MEETING) {
      MeetingService _meetingService = MeetingService();
      Meeting? m =
          await _meetingService.deleteThread(id: id, threadID: thread.id);
      if (m != null) {
        // FIXME: notifier not working well
        // MeetingsNotifier notifier =
        //     Provider.of<MeetingsNotifier>(context, listen: false);
        // notifier.edit(m);

        isThreadDeleted = true;
      }
    }

    if (isThreadDeleted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Done'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured.')),
      );
    }
  }

  void _deleteThreadDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete thread with content ${p.text} (and all of its comments)?',
            () {
          _deleteThread(context);
        });
      },
    );
  }

  void _editThreadModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: EditThreadForm(thread: thread, post: p),
        );
      },
    );
  }

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
                    if (owner)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                            onPressed: () {
                              _deleteThreadDialog(context);
                            },
                            icon: Icon(Icons.delete)),
                      ),
                    if (owner)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                            onPressed: () {
                              _editThreadModal(context);
                            },
                            icon: Icon(Icons.edit)),
                      ),
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
