import 'package:flutter/material.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:intl/intl.dart';

class EditMeetingForm extends StatefulWidget {
  final Meeting meeting;
  EditMeetingForm({Key? key, required this.meeting})
      : super(key: key);

  @override
  _EditMeetingFormState createState() => _EditMeetingFormState();
}

var kinds = ["Event", "Team", "Company"];

class _EditMeetingFormState extends State<EditMeetingForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _placeController;
  late TextEditingController _beginDateController;
  late TextEditingController _endDateController;
  final _meetingService = MeetingService();

  late DateTime _begin;
  late DateTime _end;
  late String _kind;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting.title);
    _placeController = TextEditingController(text: widget.meeting.place);
    _beginDateController =
        TextEditingController(text: getDateTime(widget.meeting.begin));
    _endDateController =
        TextEditingController(text: getDateTime(widget.meeting.end));
    _begin = widget.meeting.begin;
    _end = widget.meeting.end;
    _kind = widget.meeting.kind;
  }

  String getDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var title = _titleController.text;
      var place = _placeController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading')),
      );

      Meeting? m = await _meetingService.updateMeeting(
          widget.meeting.id, _begin.toUtc(), _end.toUtc(), place, _kind, title);
      if (m != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occured.')),
        );
      }
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
                decoration: const InputDecoration(
                  icon: const Icon(Icons.calendar_today),
                  labelText: "Begin Date *",
                ),
                readOnly: true, //prevents editing the date in the form field
                onTap: () async {
                  await _selectDateTime(context, true);
                  String formattedDate = getDateTime(_begin);

                  setState(() {
                    _beginDateController.text = formattedDate;
                  });
                },
              )),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.calendar_today),
                  labelText: "End Date *",
                ),
                readOnly: true, //prevents editing the date in the form field
                onTap: () async {
                  await _selectDateTime(context, false);
                  String formattedDate = getDateTime(_end);

                  setState(() {
                    _endDateController.text = formattedDate;
                  });
                },
              )),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                  // Transforming TEAM or COMPANY or EVENT into Team or Company or Event
                  value: "${widget.meeting.kind[0].toUpperCase()}${widget.meeting.kind.substring(1).toLowerCase()}",
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
    return _buildForm();
  }
}
