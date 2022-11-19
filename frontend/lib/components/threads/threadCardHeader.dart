import 'package:flutter/material.dart';
import 'package:frontend/components/threads/threadCard.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
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
                              print("Delete thread");
                            },
                            icon: Icon(Icons.delete)),
                      ),
                    if (owner)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                            onPressed: () {
                              print("Edit thread");
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
