import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/services/flightInfoService.dart';
import 'package:intl/intl.dart';

class EditFlightForm extends StatefulWidget {
  final FlightInfo flight;
  final void Function(BuildContext, FlightInfo?)? onFlightEdit;
  EditFlightForm({Key? key, required this.flight, required this.onFlightEdit})
      : super(key: key);

  @override
  _EditFlightFormState createState() => _EditFlightFormState();
}

class _EditFlightFormState extends State<EditFlightForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _inboundController;
  late TextEditingController _outboundController;
  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _linkController;
  late TextEditingController _notesController;
  late TextEditingController _costEurosController;
  late TextEditingController _costCentsController;
  late bool flightBought;

  final _flightService = FlightInfoService();

  late DateTime _inbound;
  late DateTime _outbound;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.flight.from);
    _toController = TextEditingController(text: widget.flight.to);
    _inboundController =
        TextEditingController(text: getDateTime(widget.flight.inbound));
    _outboundController =
        TextEditingController(text: getDateTime(widget.flight.outbound));
    _linkController = TextEditingController(text: widget.flight.link);
    _notesController = TextEditingController(text: widget.flight.notes);
    _costEurosController =
        TextEditingController(text: (widget.flight.cost ~/ 100).toString());
    _costCentsController =
        TextEditingController(text: (widget.flight.cost % 100).toString());
    _inbound = widget.flight.inbound;
    _outbound = widget.flight.outbound;
    flightBought = widget.flight.bought;
  }

  String getDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var from = _fromController.text;
      var to = _toController.text;
      var link = _linkController.text;
      var notes = _notesController.text;
      var cost = int.parse(_costEurosController.text) * 100 +
          int.parse(_costCentsController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating Flight...')),
      );

      FlightInfo f = await _flightService.updateFlightInfo(
          widget.flight.id,
          _inbound.toUtc(),
          _outbound.toUtc(),
          from,
          to,
          link,
          flightBought,
          cost,
          notes);

      if (f != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        widget.onFlightEdit!(context, f);

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
                String formattedDate = getDateTime(_outbound);

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
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _costEurosController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost of the flight';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of flight (only euros) *",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _costCentsController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost of the flight';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of flight (only cents) *",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
              ),
            ],
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
    return _buildForm();
  }
}
