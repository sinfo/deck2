import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/meeting/MeetingCard.dart';
import 'package:frontend/services/meetingService.dart';

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
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final MeetingService _service = MeetingService();
  late final Future<List<Meeting>> _meetings;
  late final TabController _tabController;

  @override
  void initState() {
    _meetings = _service.getMeetings();
    _tabController = TabController(length: 2, vsync: this);
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

          return LayoutBuilder(builder: (context, constraints) {
            bool small = constraints.maxWidth < App.SIZE;
            return Column(
              children: [
                TabBar(
                  isScrollable: small,
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
                Expanded(
                  child: TabBarView(controller: _tabController, children: [
                    ListView(
                      children: meets
                          .where((m) => DateTime.now().isBefore(m.begin))
                          .map((e) => MeetingCard(meeting: e))
                          .toList(),
                    ),
                    ListView(
                      children: meets
                          .where((m) => DateTime.now().isAfter(m.begin))
                          .map((e) => MeetingCard(meeting: e))
                          .toList(),
                    ),
                  ]),
                ),
              ],
            );
          });
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
