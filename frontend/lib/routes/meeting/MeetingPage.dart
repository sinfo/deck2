import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/meeting/MeetingCard.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:provider/provider.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({Key? key}) : super(key: key);

  @override
  _MeetingPageState createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage>
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    CustomAppBar _appBar = CustomAppBar(disableEventChange: true);
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, _appBar.preferredSize.height, 0, 0),
            child: FutureBuilder(
              future: _meetings,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  MeetingsNotifier notifier =
                      Provider.of<MeetingsNotifier>(context);

                  notifier.meetings = snapshot.data as List<Meeting>;

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
                        Consumer<MeetingsNotifier>(
                          builder: (context, cart, child) {
                            return Expanded(
                              child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    ListView(
                                      children: notifier
                                          .getUpcoming()
                                          .map((e) => MeetingCard(meeting: e))
                                          .toList(),
                                    ),
                                    ListView(
                                      children: notifier
                                          .getPast()
                                          .map((e) => MeetingCard(meeting: e))
                                          .toList(),
                                    ),
                                  ]),
                            );
                          },
                        ),
                      ],
                    );
                  });
                } else {
                  return CircularProgressIndicator();
                }
              },
            )),
        _appBar,
      ]),
      floatingActionButton: FutureBuilder(
          future: Provider.of<AuthService>(context).role,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Role r = snapshot.data as Role;

              if (r == Role.ADMIN || r == Role.COORDINATOR || r == Role.TEAMLEADER) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.AddMeeting,
                    );
                  },
                  label: const Text('Create New Meeting'),
                  icon: const Icon(Icons.add),
                );
              } else {
                return Container();
              }
            } else {
              return Container();
            }
          }),
    );
  }
}
