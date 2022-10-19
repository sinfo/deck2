import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/sessions/SessionCard.dart';
import 'package:frontend/routes/sessions/SessionsNotifier.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:provider/provider.dart';

class SessionPage extends StatelessWidget {
  const SessionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SessionList(),
    );
  }
}

class SessionList extends StatefulWidget {
  const SessionList({Key? key}) : super(key: key);

  @override
  _SessionListState createState() => _SessionListState();
}

class _SessionListState extends State<SessionList>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final SessionService _service = SessionService();
  late final Future<List<Session>> _sessions;
  late final TabController _tabController;

  @override
  void initState() {
    _sessions = _service.getSessions();
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
      future: _sessions,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // SessionsNotifier notifier = Provider.of<SessionsNotifier>(context);

          // notifier.sessions = snapshot.data as List<Session>;

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
                // Consumer<SessionsNotifier>(
                //   builder: (context, cart, child) {
                //     return Expanded(
                //       child: TabBarView(controller: _tabController, children: [
                //         ListView(
                //           children: notifier
                //               .getUpcoming()
                //               .map((e) => SessionCard(session: e))
                //               .toList(),
                //         ),
                //         ListView(
                //           children: notifier
                //               .getPast()
                //               .map((e) => SessionCard(session: e))
                //               .toList(),
                //         ),
                //       ]),
                //     );
                //   },
                // ),
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
