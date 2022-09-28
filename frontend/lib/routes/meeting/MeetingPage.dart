import 'package:flutter/material.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/routes/meeting/MeetingCard.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:provider/provider.dart';

class MeetingPage extends StatelessWidget {
  const MeetingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: MeetingList(),
    );
  }
}

class MeetingList extends StatefulWidget {
  const MeetingList({Key? key}) : super(key: key);

  @override
  _MeetingListState createState() => _MeetingListState();
}

class _MeetingListState extends State<MeetingList>
    with AutomaticKeepAliveClientMixin {
  final MeetingService _service = MeetingService();
  late final Future<List<Meeting>> _meetings;

  @override
  void initState() {
    _meetings = _service.getMeetings();
    super.initState();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: _meetings,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Meeting> meets = snapshot.data as List<Meeting>;
          return ListView(
            children: meets.map((e) => MeetingCard(meeting: e)).toList(),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
