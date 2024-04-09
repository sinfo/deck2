import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/routes/session/calendar.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/eventService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

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
  EventService _eventService = EventService();
  late final Future<List<Session>> _sessions;

  @override
  void initState() {
    _sessions = _service.getSessions();
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
              future: _sessions,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  SessionsNotifier notifier =
                      Provider.of<SessionsNotifier>(context);

                  notifier.sessions = snapshot.data as List<Session>;

                  var upcomingSessions = notifier.getAll().toList();

                  return Calendar(
                    sessions: upcomingSessions,
                    key: UniqueKey(),
                  );
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

              if (r == Role.ADMIN || r == Role.COORDINATOR) {
                return SpeedDial(
                  icon: Icons.add,
                  activeIcon: Icons.close,
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.add),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.AddSession,
                        );
                      },
                      label: 'Create New Session',
                    ),
                    // TODO: UI/UX improve this functionality
                    SpeedDialChild(
                      child: Icon(Icons.schedule),
                      onTap: () async {
                        Event? e = await _eventService.updateEventCalendar();

                        if (e == null) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Error: cannot update calendar.',
                                    style: TextStyle(color: Colors.white)),
                                duration: Duration(seconds: 2),),
                          );
                        } else {              
                          
                          // TODO: should return new calendar

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Done', style: TextStyle(color: Colors.white)),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      label: 'Update calendar file',
                    ),
                  ],
                );
                // return FloatingActionButton.extended(
                //   onPressed: () {
                //     Navigator.pushNamed(
                //       context,
                //       Routes.AddSession,
                //     );
                //   },
                //   label: const Text('Create New Session'),
                //   icon: const Icon(Icons.add),
                // );
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
