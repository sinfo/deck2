import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/services/companyService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddBillingForm extends StatefulWidget {
  final String id;
  final void Function(BuildContext, Company?)? onEditCompany;

  AddBillingForm({Key? key, required this.id, required this.onEditCompany})
      : super(key: key);

  @override
  _AddBillingFormState createState() => _AddBillingFormState();
}

class _AddBillingFormState extends State<AddBillingForm> {
  final _formKey = GlobalKey<FormState>();

  final _emissionController = TextEditingController();
  final _eventController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _valueEurosController = TextEditingController();
  final _valueCentsController = TextEditingController();

  bool invoice = false;
  bool paid = false;
  bool proForma = false;
  bool receipt = false;
  bool visible = false;

  final _companyService = CompanyService();

  DateTime? dateTime;
  DateTime? _emission;

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
      var value = int.parse(_valueEurosController.text) * 100 +
          int.parse(_valueCentsController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating Billing...')),
      );

      Company? c = await _companyService.createBilling(
          id: widget.id,
          emission: _emission!.toUtc(),
          event: event,
          invoiceNumber: invoiceNumber,
          notes: notes,
          invoice: invoice,
          paid: paid,
          proForma: proForma,
          receipt: receipt,
          value: value,
          visible: visible);

      if (c != null) {
        CompanyTableNotifier notifier =
            Provider.of<CompanyTableNotifier>(context, listen: false);
        notifier.edit(c);

        widget.onEditCompany!(context, c);

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
      Navigator.pop(context);
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
                String formattedDate = getDateTime(_emission!);

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
                labelText: "Additional notes (optional) *",
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _valueEurosController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost of the billing';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of billing (only euros) *",
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
                    controller: _valueCentsController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost of the billing';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of billing (only cents) *",
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
