import 'package:flutter/material.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditSessionForm extends StatefulWidget {
  final Session session;
  EditSessionForm({Key? key, required this.session}) : super(key: key);

  @override
  _EditSessionFormState createState() => _EditSessionFormState();
}

const kinds = ["TALK", "PRESENTATION", "WORKSHOP"];

class _EditSessionFormState extends State<EditSessionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _placeController;
  late TextEditingController _beginDateController;
  late TextEditingController _endDateController;
  final _sessionService = SessionService();

  late DateTime _begin;
  late DateTime _end;
  late String _kind;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.session.title);
    _placeController = TextEditingController(text: widget.session.place);
    _beginDateController =
        TextEditingController(text: getDateTime(widget.session.begin));
    _endDateController =
        TextEditingController(text: getDateTime(widget.session.end));
    _begin = widget.session.begin;
    _end = widget.session.end;
    _kind = widget.session.kind;
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

      // Session? s = await _sessionService.updateSession(
      //     widget.session.id, _begin.toUtc(), _end.toUtc(), place, _kind, title);

      // if (s != null) {
      //   SessionsNotifier notifier =
      //       Provider.of<SessionsNotifier>(context, listen: false);
      //   notifier.edit(s);

      //   ScaffoldMessenger.of(context).hideCurrentSnackBar();

      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Done'),
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      //   Navigator.pop(context);
      // } else {
      //   ScaffoldMessenger.of(context).hideCurrentSnackBar();

      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('An error occured.')),
      //   );
      // }
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
                  String formattedDate = getDateTime(_end);

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
                      return 'Please enter the kind of session';
                    }
                    return null;
                  },
                  // Transforming TEAM or COMPANY or EVENT into Team or Company or Event
                  value:
                      "${widget.session.kind[0].toUpperCase()}${widget.session.kind.substring(1).toLowerCase()}",
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
