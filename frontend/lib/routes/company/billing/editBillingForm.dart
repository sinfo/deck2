import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/billing.dart';
import 'package:frontend/services/billingService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditBillingForm extends StatefulWidget {
  final Billing billing;
  final void Function(BuildContext, Billing?)? onBillingEdit;
  EditBillingForm(
      {Key? key, required this.billing, required this.onBillingEdit})
      : super(key: key);

  @override
  _EditBillingFormState createState() => _EditBillingFormState();
}

class _EditBillingFormState extends State<EditBillingForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emissionController;
  late TextEditingController _eventController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _notesController;
  late TextEditingController _costController;

  late bool invoice;
  late bool paid;
  late bool proForma;
  late bool receipt;
  late bool visible;

  final _billingService = BillingService();

  late DateTime _emission;

  @override
  void initState() {
    super.initState();
    NumberFormat formatter = new NumberFormat("00");
    _emissionController =
        TextEditingController(text: getDateTime(widget.billing.emission));
    _eventController =
        TextEditingController(text: widget.billing.event.toString());
    _invoiceNumberController =
        TextEditingController(text: widget.billing.invoiceNumber);
    _notesController = TextEditingController(text: widget.billing.notes);
    _costController = TextEditingController(
        text: (widget.billing.value ~/ 100).toString() + "." +
            formatter.format(widget.billing.value % 100));
    invoice = widget.billing.status.invoice;
    paid = widget.billing.status.paid;
    proForma = widget.billing.status.proForma;
    receipt = widget.billing.status.receipt;
    visible = widget.billing.visible;

    _emission = widget.billing.emission;
  }

  String getDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  void _checkBillingEvent() async {
    int event = int.parse(_eventController.text);
    int currentEvent =
        Provider.of<EventNotifier>(context, listen: false).event.id;
    if (event != currentEvent) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return BlurryDialog(
              'Warning',
              'Are you sure you want to add a billing for SINFO ' +
                  event.toString() +
                  ' instead of SINFO ' +
                  currentEvent.toString() +
                  '?', () {
            _submit();
          });
        },
      );
    } else {
      _submit();
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var event = int.parse(_eventController.text);
      var invoiceNumber = _invoiceNumberController.text;
      var notes = _notesController.text;
      var parseCost = double.parse(_costController.text);
      var euros = parseCost.toInt();
      var cents = ((parseCost - euros) * 100).round();
      int cost = euros * 100 + cents;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Updating Billing...',
                style: TextStyle(color: Colors.white))),
      );

      Billing? b = await _billingService.updateBilling(
          id: widget.billing.id,
          emission: _emission.toUtc(),
          event: event,
          invoiceNumber: invoiceNumber,
          notes: notes,
          invoice: invoice,
          paid: paid,
          proForma: proForma,
          receipt: receipt,
          value: cost,
          visible: visible);

      if (b != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        widget.onBillingEdit!(context, b);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occured.',
                  style: TextStyle(color: Colors.white))),
        );
      }
    }
  }

  Future _selectDateTime(BuildContext context) async {
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
      _emission = DateTime(datePicker.year, datePicker.month, datePicker.day,
          timePicker.hour, timePicker.minute);
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
              controller: _emissionController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the billing emission date';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.calendar_today),
                labelText: "Emission Date *",
              ),
              readOnly: true, //prevents editing the date in the form field
              onTap: () async {
                await _selectDateTime(context);
                String formattedDate = getDateTime(_emission);

                setState(() {
                  _emissionController.text = formattedDate;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _eventController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid event';
                }
                int event = int.parse(value);
                if (event <= 0) {
                  return 'Please enter a valid event';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.money),
                labelText: "Event *",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _invoiceNumberController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the billing invoice number';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Invoice Number *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                icon: const Icon(Icons.note),
                labelText: "Additional notes (optional)",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _costController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the cost of the billing';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.money),
                labelText: "Cost of billing *",
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
            ),
          ),
          CheckboxListTile(
            value: this.invoice,
            onChanged: (val) {
              setState(() {
                this.invoice = !this.invoice;
              });
            },
            title: new Text('Invoice'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          ),
          CheckboxListTile(
            value: this.paid,
            onChanged: (val) {
              setState(() {
                this.paid = !this.paid;
              });
            },
            title: new Text('Paid'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          ),
          CheckboxListTile(
            value: this.proForma,
            onChanged: (val) {
              setState(() {
                this.proForma = !this.proForma;
              });
            },
            title: new Text('ProForma'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          ),
          CheckboxListTile(
            value: this.receipt,
            onChanged: (val) {
              setState(() {
                this.receipt = !this.receipt;
              });
            },
            title: new Text('Receipt'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _checkBillingEvent(),
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
