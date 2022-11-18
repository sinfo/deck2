import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/session/EditSessionForm.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/session.dart';
import '../../services/authService.dart';

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
  final _sessionService = SessionService();
  CalendarFormat format = CalendarFormat.month;
  SpeakerService speakerService = SpeakerService();
  CompanyService companyService = CompanyService();
  List<Speaker> speakers30 = [];
  List<Speaker> speakers29 = [];
  List<Speaker> speakers28 = [];
  List<Speaker> speakers27 = [];
  List<Speaker> speakers26 = [];
  List<Speaker> speakers25 = [];
  List<Speaker> speakers24 = [];
  List<Speaker> speakers23 = [];
  List<Speaker> speakers22 = [];
  List<Speaker> speakers21 = [];
  List<Speaker> allSpeakers = [];

  List<Company> companies30 = [];
  List<Company> companies29 = [];
  List<Company> companies28 = [];
  List<Company> companies27 = [];
  List<Company> companies26 = [];
  List<Company> companies25 = [];
  List<Company> companies24 = [];
  List<Company> companies23 = [];
  List<Company> companies22 = [];
  List<Company> companies21 = [];
  List<Company> allCompanies = [];

  late Map<DateTime, List<Session>> calendarSessions;

  _CalendarState({required this.sessions});

  @override
  void initState() {
    selectedCalendarDate = _focusedCalendarDate;
    calendarSessions = {};
    fillCalendarSessions();
    fillSpeakers();
    fillCompanies();
    super.initState();
  }

  Future<void> fillSpeakers() async {
    Future<List<Speaker>> speakersFuture30 =
        speakerService.getSpeakers(eventId: 30);
    // for (int i = 22; i < 30; i++){
    //   speakersFuture.
    // }
    Future<List<Speaker>> speakersFuture29 =
        speakerService.getSpeakers(eventId: 29);
    Future<List<Speaker>> speakersFuture28 =
        speakerService.getSpeakers(eventId: 28);
    Future<List<Speaker>> speakersFuture27 =
        speakerService.getSpeakers(eventId: 27);
    Future<List<Speaker>> speakersFuture26 =
        speakerService.getSpeakers(eventId: 26);
    Future<List<Speaker>> speakersFuture25 =
        speakerService.getSpeakers(eventId: 25);
    Future<List<Speaker>> speakersFuture24 =
        speakerService.getSpeakers(eventId: 24);
    Future<List<Speaker>> speakersFuture23 =
        speakerService.getSpeakers(eventId: 23);
    Future<List<Speaker>> speakersFuture22 =
        speakerService.getSpeakers(eventId: 22);
    Future<List<Speaker>> speakersFuture21 =
        speakerService.getSpeakers(eventId: 21);
    speakers30 = await speakersFuture30;
    speakers29 = await speakersFuture29;
    speakers28 = await speakersFuture28;
    speakers27 = await speakersFuture27;
    speakers26 = await speakersFuture26;
    speakers25 = await speakersFuture25;
    speakers24 = await speakersFuture24;
    speakers23 = await speakersFuture23;
    speakers22 = await speakersFuture22;
    speakers21 = await speakersFuture21;
    allSpeakers = speakers30;
    allSpeakers.addAll(speakers29);
    allSpeakers.addAll(speakers28);
    allSpeakers.addAll(speakers27);
    allSpeakers.addAll(speakers26);
    allSpeakers.addAll(speakers25);
    allSpeakers.addAll(speakers24);
    allSpeakers.addAll(speakers23);
    allSpeakers.addAll(speakers22);
    allSpeakers.addAll(speakers21);

    print(allSpeakers);
  }

  Future<void> fillCompanies() async {
    Future<List<Company>> companiesFuture30 =
        companyService.getCompanies(event: 30);

    Future<List<Company>> companiesFuture29 =
        companyService.getCompanies(event: 29);
    Future<List<Company>> companiesFuture28 =
        companyService.getCompanies(event: 28);
    Future<List<Company>> companiesFuture27 =
        companyService.getCompanies(event: 27);
    Future<List<Company>> companiesFuture26 =
        companyService.getCompanies(event: 26);
    Future<List<Company>> companiesFuture25 =
        companyService.getCompanies(event: 25);
    Future<List<Company>> companiesFuture24 =
        companyService.getCompanies(event: 24);
    Future<List<Company>> companiesFuture23 =
        companyService.getCompanies(event: 23);
    Future<List<Company>> companiesFuture22 =
        companyService.getCompanies(event: 22);
    Future<List<Company>> companiesFuture21 =
        companyService.getCompanies(event: 21);
    companies30 = await companiesFuture30;
    companies29 = await companiesFuture29;
    companies28 = await companiesFuture28;
    companies27 = await companiesFuture27;
    companies26 = await companiesFuture26;
    companies25 = await companiesFuture25;
    companies24 = await companiesFuture24;
    companies23 = await companiesFuture23;
    companies22 = await companiesFuture22;
    companies21 = await companiesFuture21;
    allCompanies = companies30;
    allCompanies.addAll(companies29);
    allCompanies.addAll(companies28);
    allCompanies.addAll(companies27);
    allCompanies.addAll(companies26);
    allCompanies.addAll(companies25);
    allCompanies.addAll(companies24);
    allCompanies.addAll(companies23);
    allCompanies.addAll(companies22);
    allCompanies.addAll(companies21);
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
    // print("Speakers names " + speakersNames.toString());
    return speakersNames;
  }

  Future<String> _getCompanies(String? id) async {
    Future<Company?> companyFuture = companyService.getCompany(id: id!);
    Company? company = await companyFuture;
    String? companyName = company!.name;
    // String companyName = "default";
    for (var company in allCompanies) {
      if (company.id == id) {
        // companyName = company.name;
      }
    }
    return companyName;
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
              eventLoader: _listOfDaySessions,
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
            ..._listOfDaySessions(selectedCalendarDate!).map(
              (calSessions) => ExpansionTile(
                  childrenPadding: const EdgeInsets.all(8.0),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  expandedAlignment: Alignment.topLeft,
                  leading: const Icon(
                    Icons.done,
                    color: Colors.blue,
                  ),
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(calSessions.kind.toUpperCase() +
                        ' - ' +
                        calSessions.title),
                  ),
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description: ' + calSessions.description),
                            Text('From ' +
                                DateFormat.jm()
                                    .format(calSessions.begin.toLocal()) +
                                ' to ' +
                                DateFormat.jm()
                                    .format(calSessions.end.toLocal())),
                            Text(calSessions.place ?? 'No place available yet'),
                            Text(calSessions.videoURL ??
                                'No video available yet'),
                            (calSessions.tickets != null)
                                ? Text('Tickets\n' +
                                    '*Quantity: ' +
                                    calSessions.tickets!.max.toString() +
                                    '\n*Available from ' +
                                    DateFormat.yMd().format(
                                        calSessions.tickets!.start!.toLocal()) +
                                    ' at ' +
                                    DateFormat.jm().format(
                                        calSessions.tickets!.start!.toLocal()) +
                                    ' to ' +
                                    DateFormat.yMd().format(
                                        calSessions.tickets!.end!.toLocal()) +
                                    calSessions.tickets!.start!.month
                                        .toString() +
                                    ' at ' +
                                    DateFormat.jm().format(
                                        calSessions.tickets!.start!.toLocal()))
                                : Text('No tickets available for this session'),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                (calSessions.kind == 'TALK')
                                    ? SizedBox(
                                        width: 500.0,
                                        height: 220.0,
                                        child: Card(
                                          child: Column(children: [
                                            Text(
                                              "Speakers",
                                              style: TextStyle(
                                                fontSize: 20.0,
                                                color: Color.fromARGB(
                                                    255, 63, 81, 181),
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                _getSpeakers(
                                                        calSessions.speakersIds)
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 25.0,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          ]),
                                        ))
                                    : SizedBox(
                                        width: 250.0,
                                        height: 120.0,
                                        child: Card(
                                          child: Column(children: [
                                            Text(
                                              "Company",
                                              style: TextStyle(
                                                fontSize: 20.0,
                                                color: Color.fromARGB(
                                                    255, 63, 81, 181),
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: FutureBuilder(
                                                    future: _getCompanies(
                                                        calSessions.companyId),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot.hasData) {
                                                        final companyName =
                                                            snapshot.data;
                                                        return Text(companyName
                                                            .toString());
                                                      } else {
                                                        return Text(
                                                            "Loading...");
                                                      }
                                                    }))
                                          ]),
                                        ))
                              ]),
                        ),
                        // ..._getSpeakers(calSessions.speakersIds)
                        //     .map((name) => ListTile(
                        //           title: Padding(
                        //             padding: const EdgeInsets.all(8.0),
                        //             child: Text(name),
                        //           ),
                        //         )),
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
                                                    context, calSessions.id);
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
                                                                calSessions.id),
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
