import 'package:flutter/material.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/routes/session/calendar.dart';
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

  @override
  void initState() {
    _sessions = _service.getSessions();
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
          SessionsNotifier notifier = Provider.of<SessionsNotifier>(context);

          notifier.sessions = snapshot.data as List<Session>;

          var upcomingSessions = notifier.getUpcoming().toList();

          return Calendar(sessions: upcomingSessions);
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
