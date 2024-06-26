import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddMeetingForm extends StatefulWidget {
  AddMeetingForm({Key? key}) : super(key: key);

  @override
  _AddMeetingFormState createState() => _AddMeetingFormState();
}

const kinds = ["Event", "Team", "Company"];

class _AddMeetingFormState extends State<AddMeetingForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _beginDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _meetingService = MeetingService();

  DateTime? dateTime;
  DateTime? _begin;
  DateTime? _end;

  String _kind = "";

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var title = _titleController.text;
      var place = _placeController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Uploading', style: TextStyle(color: Colors.white))),
      );

      Meeting? m = await _meetingService.createMeeting(
          _begin!.toUtc(), _end!.toUtc(), place, _kind, title);
      if (m != null) {
        MeetingsNotifier notifier =
            Provider.of<MeetingsNotifier>(context, listen: false);
        notifier.add(m);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                _meetingService.deleteMeeting(m.id);
                notifier.remove(m);
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occured.',
                  style: TextStyle(color: Colors.white))),
        );
      }
      Navigator.pop(context);
    }
  }

  Future _selectDateTime(BuildContext context, bool isBegin) async {
    final datePicker = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );

    final timePicker = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        });

    if (datePicker != null && timePicker != null) {
      if (isBegin) {
        _begin = DateTime(datePicker.year, datePicker.month, datePicker.day,
            timePicker.hour, timePicker.minute);
      } else {
        _end = DateTime(datePicker.year, datePicker.month, datePicker.day,
            timePicker.hour, timePicker.minute);
      }
    }
  }

  String getDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _titleController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Title *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _placeController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a place';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.place),
                labelText: "Place *",
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _beginDateController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a beggining date';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  icon: const Icon(Icons.calendar_today),
                  labelText: "Begin Date *",
                ),
                readOnly: true, //prevents editing the date in the form field
                onTap: () async {
                  await _selectDateTime(context, true);
                  String formattedDate = getDateTime(_begin!);

                  setState(() {
                    _beginDateController.text = formattedDate;
                  });
                },
              )),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _endDateController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an ending date';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  icon: const Icon(Icons.calendar_today),
                  labelText: "End Date *",
                ),
                readOnly: true, //prevents editing the date in the form field
                onTap: () async {
                  await _selectDateTime(context, false);
                  String formattedDate = getDateTime(_end!);

                  setState(() {
                    _endDateController.text = formattedDate;
                  });
                },
              )),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                  validator: (value) {
                    if (value == null) {
                      return 'Please enter the kind of the meeting';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.category),
                    labelText: "Kind *",
                  ),
                  items: kinds.map((String kind) {
                    return new DropdownMenuItem(value: kind, child: Text(kind));
                  }).toList(),
                  onChanged: (newValue) {
                    // do other stuff with _category
                    setState(() => _kind = newValue.toString());
                  })),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _submit(),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CustomAppBar appBar = CustomAppBar(
      disableEventChange: true,
    );
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: _buildForm()),
        appBar,
      ]),
    );
  }
}
