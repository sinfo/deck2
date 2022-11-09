import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/session.dart';

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

  // _showAddEventDialog() async {
  //   await showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //             title: const Text('New Event'),
  //             content: Column(
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 buildTextField(
  //                     controller: titleController, hint: 'Enter Title'),
  //                 const SizedBox(
  //                   height: 20.0,
  //                 ),
  //                 buildTextField(
  //                     controller: descpController, hint: 'Enter Description'),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('Cancel'),
  //               ),
  //               TextButton(
  //                 onPressed: () {
  //                   if (titleController.text.isEmpty &&
  //                       descpController.text.isEmpty) {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                         content: Text('Please enter title & description'),
  //                         duration: Duration(seconds: 3),
  //                       ),
  //                     );
  //                     //Navigator.pop(context);
  //                     return;
  //                   } else {
  //                     setState(() {
  //                       if (mySelectedEvents[selectedCalendarDate] != null) {
  //                         mySelectedEvents[selectedCalendarDate]?.add(MyEvents(
  //                             eventTitle: titleController.text,
  //                             eventDescp: descpController.text));
  //                       } else {
  //                         mySelectedEvents[selectedCalendarDate!] = [
  //                           MyEvents(
  //                               eventTitle: titleController.text,
  //                               eventDescp: descpController.text)
  //                         ];
  //                       }
  //                     });

  //                     titleController.clear();
  //                     descpController.clear();

  //                     Navigator.pop(context);
  //                     return;
  //                   }
  //                 },
  //                 child: const Text('Add'),
  //               ),
  //             ],
  //           ));
  // }

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
      appBar: AppBar(
        title: const Text('Custom Calendar'),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showAddEventDialog(),
      //   label: const Text('Add Event'),
      // ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 5.0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
                side: BorderSide(color: Colors.blueAccent, width: 2.0),
              ),
              child: TableCalendar(
                focusedDay: _focusedCalendarDate,
                // today's date
                firstDay: _initialCalendarDate,
                // earliest possible date
                lastDay: _lastCalendarDate,
                // latest allowed date
                calendarFormat: CalendarFormat.month,
                // default view when displayed
                // default is Saturday & Sunday but can be set to any day.
                // instead of day number can be mentioned as well.
                weekendDays: const [DateTime.sunday, 6],
                // default is Sunday but can be changed according to locale
                startingDayOfWeek: StartingDayOfWeek.monday,
                // height between the day row and 1st date row, default is 16.0
                daysOfWeekHeight: 40.0,
                // height between the date rows, default is 52.0
                rowHeight: 60.0,
                // this property needs to be added if we want to show events
                eventLoader: _listOfDayEvents,
                // Calendar Header Styling
                headerStyle: const HeaderStyle(
                  titleTextStyle:
                      TextStyle(color: Colors.lightBlue, fontSize: 20.0),
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10))),
                  formatButtonTextStyle:
                      TextStyle(color: Colors.blueAccent, fontSize: 16.0),
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.lightBlue,
                    borderRadius: BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.lightBlue,
                    size: 28,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.lightBlue,
                    size: 28,
                  ),
                ),
                // Calendar Days Styling
                daysOfWeekStyle: const DaysOfWeekStyle(
                  // Weekend days color (Sat,Sun)
                  weekendStyle: TextStyle(color: Colors.blueAccent),
                ),
                // Calendar Dates styling
                calendarStyle: const CalendarStyle(
                  // Weekend dates color (Sat & Sun Column)
                  weekendTextStyle: TextStyle(color: Colors.blueAccent),
                  // highlighted color for today
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  // highlighted color for selected day
                  selectedDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration:
                      BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
                selectedDayPredicate: (currentSelectedDate) {
                  // as per the documentation 'selectedDayPredicate' needs to determine
                  // current selected day
                  return (isSameDay(
                      selectedCalendarDate!, currentSelectedDate));
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
            ),
            ..._listOfDayEvents(selectedCalendarDate!).map(
              (myEvents) => ListTile(
                leading: const Icon(
                  Icons.done,
                  color: Colors.blue,
                ),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                      myEvents.kind.toUpperCase() + ' - ' + myEvents.title),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description: ' + myEvents.description),
                    Text('From ' +
                        myEvents.begin.hour.toString() +
                        ':' +
                        myEvents.begin.minute.toString() +
                        ' to ' +
                        myEvents.end.hour.toString() +
                        ':' +
                        myEvents.end.minute.toString()),
                    Text(myEvents.place ?? 'No place available yet'),
                    Text(myEvents.videoURL ?? 'No video available yet'),
                    (myEvents.tickets != null)
                        ? Text('Tickets\n' +
                            '*Quantity: ' +
                            myEvents.tickets!.max.toString() +
                            '\n*Available from ' +
                            myEvents.tickets!.start!.day.toString() +
                            '/' +
                            myEvents.tickets!.start!.month.toString() +
                            '/' +
                            myEvents.tickets!.start!.year.toString() +
                            ' at ' +
                            myEvents.tickets!.start!.hour.toString() +
                            ':' +
                            myEvents.tickets!.start!.minute.toString() +
                            ' to ' +
                            myEvents.tickets!.start!.day.toString() +
                            '/' +
                            myEvents.tickets!.start!.month.toString() +
                            '/' +
                            myEvents.tickets!.start!.year.toString() +
                            ' at ' +
                            myEvents.tickets!.end!.hour.toString() +
                            ':' +
                            myEvents.tickets!.end!.minute.toString())
                        : Text('No tickets available for this session'),
                  ],
                ),
              ),
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
