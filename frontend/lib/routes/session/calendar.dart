import 'package:flutter/material.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/session/SessionScreen.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  final List<Session> sessions;
  const Calendar({Key? key, required this.sessions}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState(sessions: sessions);
}

class _CalendarState extends State<Calendar> {
  final todaysDate = DateTime.now();
  var _focusedCalendarDate = DateTime.now();
  final _initialCalendarDate = DateTime(2000);
  final _lastCalendarDate = DateTime(2050);
  DateTime? selectedCalendarDate;
  final titleController = TextEditingController();
  final descpController = TextEditingController();
  final List<Session> sessions;
  CalendarFormat format = CalendarFormat.month;
  SpeakerService speakerService = SpeakerService();
  CompanyService companyService = CompanyService();

  List<Speaker> allSpeakers = [];

  late Map<DateTime, List<Session>> calendarSessions;

  _CalendarState({required this.sessions});

  @override
  void initState() {
    selectedCalendarDate = _focusedCalendarDate;
    calendarSessions = {};
    fillCalendarSessions();
    fillSpeakers();
    super.initState();
  }

  Future<void> fillSpeakers() async {
    Future<List<Speaker>> speakersFuture = speakerService.getSpeakers();

    allSpeakers = await speakersFuture;
  }

  void fillCalendarSessions() {
    for (var session in sessions) {
      DateTime dateForCalendar =
          DateTime(session.begin.year, session.begin.month, session.begin.day);

      setState(() {
        if (calendarSessions[dateForCalendar.toUtc()] != null) {
          calendarSessions[dateForCalendar.toUtc()]!.add(session);
        } else {
          calendarSessions[dateForCalendar!.toUtc()] = [session];
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

  List<Session> _listOfDaySessions(DateTime dateTime) {
    return calendarSessions[dateTime] ?? [];
  }

  List<String> _getSpeakers(List<String>? ids) {
    List<String> speakersNames = [];
    for (var speaker in allSpeakers) {
      for (var id in ids!) {
        if (speaker.id == id && (!speakersNames.contains(speaker.name))) {
          speakersNames.add(speaker.name);
        }
      }
    }
    return speakersNames;
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
              eventLoader: _listOfDaySessions,
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(
                    color: Color.fromARGB(255, 63, 81, 181), fontSize: 25.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
                formatButtonShowsNext: false,
                formatButtonTextStyle: TextStyle(fontSize: 16.0),
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
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekendStyle:
                    TextStyle(color: Color.fromARGB(255, 63, 81, 181)),
              ),
              calendarStyle: const CalendarStyle(
                weekendTextStyle:
                    TextStyle(color: Color.fromARGB(255, 63, 81, 181)),
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color.fromARGB(255, 63, 81, 181),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                    color: Color.fromARGB(255, 247, 172, 42),
                    shape: BoxShape.circle),
              ),
              selectedDayPredicate: (currentSelectedDate) {
                return (isSameDay(selectedCalendarDate!, currentSelectedDate));
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(selectedCalendarDate, selectedDay)) {
                  setState(() {
                    selectedCalendarDate = selectedDay;
                    _focusedCalendarDate = focusedDay;
                  });
                }
              },
            ),
            ..._listOfDaySessions(selectedCalendarDate!)
                .map((calSessions) => InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SessionScreen(
                                      session: calSessions,
                                    )));
                      },
                      child: Card(
                        elevation: 20,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        margin: EdgeInsets.only(top: 15),
                        child: Container(
                          height: 80.0,
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  calSessions.kind,
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 63, 81, 181),
                                      fontSize: 14.0),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  calSessions.title,
                                  style: TextStyle(fontSize: 18.0),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}
