import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddFlightInfoForm extends StatefulWidget {
  final String id;
  final void Function(BuildContext, Speaker?)? onEditSpeaker;

  AddFlightInfoForm({Key? key, required this.id, required this.onEditSpeaker})
      : super(key: key);

  @override
  _AddFlightInfoFormState createState() => _AddFlightInfoFormState();
}

class _AddFlightInfoFormState extends State<AddFlightInfoForm> {
  final _formKey = GlobalKey<FormState>();

  final _inboundController = TextEditingController();
  final _outboundController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _linkController = TextEditingController();
  final _notesController = TextEditingController();
  final _costController = TextEditingController();
  bool flightBought = false;

  final _speakerService = SpeakerService();

  DateTime? dateTime;
  DateTime? _inbound;
  DateTime? _outbound;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var from = _fromController.text;
      var to = _toController.text;
      var link = _linkController.text;
      var notes = _notesController.text;
      var parseCost = double.parse(_costController.text);
      var euros = parseCost.toInt();
      var cents = ((parseCost - euros) * 100).round();
      int cost = euros * 100 + cents;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Creating Flight...',
                style: TextStyle(color: Colors.white))),
      );

      Speaker? s = await _speakerService.addFlightInfo(
          id: widget.id,
          bought: flightBought,
          cost: cost,
          from: from,
          to: to,
          inbound: _inbound!.toUtc(),
          outbound: _outbound!.toUtc(),
          link: link,
          notes: notes);

      if (s != null) {
        SpeakerTableNotifier notifier =
            Provider.of<SpeakerTableNotifier>(context, listen: false);
        notifier.edit(s);

        widget.onEditSpeaker!(context, s);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
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

  Future _selectDateTime(BuildContext context, bool isInbound) async {
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
      if (isInbound) {
        _inbound = DateTime(datePicker.year, datePicker.month, datePicker.day,
            timePicker.hour, timePicker.minute);
      } else {
        _outbound = DateTime(datePicker.year, datePicker.month, datePicker.day,
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
              controller: _fromController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter departure place of the flight';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Departure place *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _outboundController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a departure date of the flight';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.calendar_today),
                labelText: "Departure Date *",
              ),
              readOnly: true, //prevents editing the date in the form field
              onTap: () async {
                await _selectDateTime(context, false);
                String formattedDate = getDateTime(_outbound!);

                setState(() {
                  _outboundController.text = formattedDate;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _toController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the arrival place of the flight';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Arrival place *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _inboundController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an arrival date of the flight';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.calendar_today),
                labelText: "Arrival Date *",
              ),
              readOnly: true, //prevents editing the date in the form field
              onTap: () async {
                await _selectDateTime(context, true);
                String formattedDate = getDateTime(_inbound!);

                setState(() {
                  _inboundController.text = formattedDate;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _linkController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the link of the flight';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.flight),
                labelText: "Link of flight *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _costController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the cost of the flight';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.money),
                labelText: "Cost of flight *",
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                icon: const Icon(Icons.note),
                labelText: "Additional notes (optional) *",
              ),
            ),
          ),
          CheckboxListTile(
            value: this.flightBought,
            onChanged: (val) {
              setState(() {
                this.flightBought = !this.flightBought;
              });
            },
            title: new Text('Flight bought.'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          ),
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
