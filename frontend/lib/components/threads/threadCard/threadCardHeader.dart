import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/threads/editThreadForm.dart';
import 'package:frontend/components/threads/threadCard/threadCard.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ThreadCardHeader extends StatelessWidget {
  final Post p;
  final Thread thread;
  final bool small;
  final void Function(BuildContext, Thread?) onEditThread;
  final void Function(String) onCommunicationDeleted;

  const ThreadCardHeader(
      {Key? key,
      required this.p,
      required this.thread,
      required this.small,
      required this.onEditThread,
      required this.onCommunicationDeleted})
      : super(key: key);

  void _deleteThreadDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete thread with content ${p.text} (and all of its comments)?',
            () {
          onCommunicationDeleted(thread.id);
        });
      },
    );
  }

  void _editThreadModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: EditThreadForm(
              thread: thread, post: p, onEditThread: onEditThread),
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
            return Wrap(
              children: [
                Wrap(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      child: Image.network(
                        m.image!,
                        width: 50,
                        height: 50,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/noImage.png',
                            width: 50,
                            height: 50,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(thread.posted),
                            style: TextStyle(fontSize: 14),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: THREADCOLOR[thread.status],
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          thread.status,
                          style: TextStyle(fontSize: 16),
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
