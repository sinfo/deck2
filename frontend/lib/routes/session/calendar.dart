import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/routes/session/EditSessionForm.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/session.dart';
import '../../services/authService.dart';

class CustomTableCalendar extends StatefulWidget {
  final List<Session> sessions;
  const CustomTableCalendar({Key? key, required this.sessions})
      : super(key: key);

  @override
  _CustomTableCalendarState createState() =>
      _CustomTableCalendarState(sessions: sessions);
}

class _CustomTableCalendarState extends State<CustomTableCalendar> {
  final todaysDate = DateTime.now();
  var _focusedCalendarDate = DateTime.now();
  final _initialCalendarDate = DateTime(2000);
  final _lastCalendarDate = DateTime(2050);
  DateTime? selectedCalendarDate;
  final titleController = TextEditingController();
  final descpController = TextEditingController();
  final List<Session> sessions;
  final _sessionService = SessionService();
  CalendarFormat format = CalendarFormat.month;

  late Map<DateTime, List<Session>> mySelectedEvents;

  _CustomTableCalendarState({required this.sessions});

  @override
  void initState() {
    selectedCalendarDate = _focusedCalendarDate;
    mySelectedEvents = {};
    fillMySelectedEvents();
    super.initState();
    // print("Sessions no calendar state");
    // print(sessions);
  }

  void fillMySelectedEvents() {
    for (var session in sessions) {
      DateTime dateForCalendar =
          DateTime(session.begin.year, session.begin.month, session.begin.day);
      print("New date for calendar");
      print(dateForCalendar.toUtc());
      setState(() {
        if (mySelectedEvents[dateForCalendar.toUtc()] != null) {
          print(
              "HEREEEEE****************************************************+");
          mySelectedEvents[session.begin]?.add(session);
        } else {
          mySelectedEvents[dateForCalendar!.toUtc()] = [session];
        }
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descpController.dispose();
    super.dispose();
  }

  List<Session> _listOfDayEvents(DateTime dateTime) {
    // mySelectedEvents[selectedCalendarDate!] = [
    //   MyEvents(eventTitle: 'titulo', eventDescp: 'descpController.text')
    // ];
    //print(mySelectedEvents);
    print(mySelectedEvents);

    return mySelectedEvents[dateTime] ?? [];
  }

  void _deleteSessionDialog(context, id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog(
            'Warning', 'Are you sure you want to delete session?', () {
          _deleteSession(context, id);
        });
      },
    );
  }

  void _deleteSession(context, id) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting')),
    );

    Session? s = await _sessionService.deleteSession(id);
    if (s != null) {
      SessionsNotifier notifier =
          Provider.of<SessionsNotifier>(context, listen: false);
      notifier.remove(s);

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

  Future<void> _editSessionModal(context, id) async {
    Future<Session> sessionFuture = _sessionService.getSession(id);
    Session session = await sessionFuture;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditSessionForm(session: session),
            ));
      },
    );
  }

  Widget buildTextField(
      {String? hint, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: hint ?? '',
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          borderRadius: BorderRadius.circular(
            10.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          borderRadius: BorderRadius.circular(
            10.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedCalendarDate,
              firstDay: _initialCalendarDate,
              lastDay: _lastCalendarDate,
              calendarFormat: format,
              onFormatChanged: (CalendarFormat _format) {
                setState(() {
                  format = _format;
                });
              },
              weekendDays: const [DateTime.sunday, 6],
              startingDayOfWeek: StartingDayOfWeek.monday,
              daysOfWeekHeight: 40.0,
              rowHeight: 60.0,
              eventLoader: _listOfDayEvents,
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(
                    color: Color.fromARGB(255, 63, 81, 181), fontSize: 25.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
                formatButtonShowsNext: false,
                formatButtonTextStyle:
                    TextStyle(color: Colors.white, fontSize: 16.0),
                formatButtonDecoration: BoxDecoration(
                  color: Color.fromARGB(255, 63, 81, 181),
                  borderRadius: BorderRadius.all(
                    Radius.circular(5.0),
                  ),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Color.fromARGB(255, 63, 81, 181),
                  size: 28,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 63, 81, 181),
                  size: 28,
                ),
              ),
              // Calendar Days Styling
              daysOfWeekStyle: const DaysOfWeekStyle(
                // Weekend days color (Sat,Sun)
                weekendStyle:
                    TextStyle(color: Color.fromARGB(255, 63, 81, 181)),
              ),
              // Calendar Dates styling
              calendarStyle: const CalendarStyle(
                // Weekend dates color (Sat & Sun Column)
                weekendTextStyle:
                    TextStyle(color: Color.fromARGB(255, 63, 81, 181)),
                // highlighted color for today
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                // highlighted color for selected day
                selectedDecoration: BoxDecoration(
                  color: Color.fromARGB(255, 63, 81, 181),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                    color: Color.fromARGB(255, 247, 172, 42),
                    shape: BoxShape.circle),
              ),
              selectedDayPredicate: (currentSelectedDate) {
                // as per the documentation 'selectedDayPredicate' needs to determine
                // current selected day
                return (isSameDay(selectedCalendarDate!, currentSelectedDate));
              },
              onDaySelected: (selectedDay, focusedDay) {
                // as per the documentation
                if (!isSameDay(selectedCalendarDate, selectedDay)) {
                  setState(() {
                    selectedCalendarDate = selectedDay;
                    _focusedCalendarDate = focusedDay;
                  });
                }
              },
            ),
            ..._listOfDayEvents(selectedCalendarDate!).map(
              (myEvents) => ExpansionTile(
                  childrenPadding: const EdgeInsets.all(8.0),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  expandedAlignment: Alignment.topLeft,
                  leading: const Icon(
                    Icons.done,
                    color: Colors.blue,
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                        myEvents.kind.toUpperCase() + ' - ' + myEvents.title),
                  ),
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description: ' + myEvents.description),
                            Text('From ' +
                                DateFormat.jm()
                                    .format(myEvents.begin.toLocal()) +
                                ' to ' +
                                DateFormat.jm().format(myEvents.end.toLocal())),
                            Text(myEvents.place ?? 'No place available yet'),
                            Text(myEvents.videoURL ?? 'No video available yet'),
                            (myEvents.tickets != null)
                                ? Text('Tickets\n' +
                                    '*Quantity: ' +
                                    myEvents.tickets!.max.toString() +
                                    '\n*Available from ' +
                                    DateFormat.yMd().format(
                                        myEvents.tickets!.start!.toLocal()) +
                                    ' at ' +
                                    DateFormat.jm().format(
                                        myEvents.tickets!.start!.toLocal()) +
                                    ' to ' +
                                    DateFormat.yMd().format(
                                        myEvents.tickets!.end!.toLocal()) +
                                    myEvents.tickets!.start!.month.toString() +
                                    ' at ' +
                                    DateFormat.jm().format(
                                        myEvents.tickets!.start!.toLocal()))
                                : Text('No tickets available for this session'),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                _editSessionModal(
                                                    context, myEvents.id);
                                              },
                                              icon: Icon(Icons.edit),
                                              color: const Color(0xff5c7ff2)),
                                          FutureBuilder(
                                              future: Provider.of<AuthService>(
                                                      context)
                                                  .role,
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  Role r =
                                                      snapshot.data as Role;

                                                  if (r == Role.ADMIN ||
                                                      r == Role.COORDINATOR) {
                                                    return IconButton(
                                                        onPressed: () =>
                                                            _deleteSessionDialog(
                                                                context,
                                                                myEvents.id),
                                                        icon:
                                                            Icon(Icons.delete),
                                                        color: Colors.red);
                                                  } else {
                                                    return Container();
                                                  }
                                                } else {
                                                  return Container();
                                                }
                                              })
                                        ]),
                                  ])),
                        ),
                      ],
                    )
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

class MyEvents {
  final String eventTitle;
  final String eventDescp;

  MyEvents({required this.eventTitle, required this.eventDescp});

  @override
  String toString() => eventTitle;
}
