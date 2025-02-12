import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';

class AddSessionForm extends StatefulWidget {
  AddSessionForm({Key? key}) : super(key: key);

  @override
  _AddSessionFormState createState() => _AddSessionFormState();
}

const kinds = ["Talk", "Presentation", "Workshop"];

class _AddSessionFormState extends State<AddSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _beginDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoURLController = TextEditingController();
  final _ticketBeginDateController = TextEditingController();
  final _ticketEndDateController = TextEditingController();
  final _sessionService = SessionService();

  late Future<List<Speaker>> speakers;

  SpeakerService speakerService = new SpeakerService();
  CompanyService companyService = new CompanyService();

  DateTime? dateTime;
  DateTime? _begin;
  DateTime? _end;
  DateTime? _beginTicket;
  DateTime? _endTicket;
  List<String> speakersIds = [];
  String? companyId;

  String _kind = "";
  bool value = false;
  double _currentTicketsValue = 0;
  bool _ticketsOn = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var title = _titleController.text;
      var description = _descriptionController.text;
      var place = _placeController.text;
      var maxTickets = _currentTicketsValue;
      var videoURL = _videoURLController.text;

      var sessionTickets = new SessionTickets(
          max: maxTickets as int, start: _beginTicket, end: _endTicket);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Uploading', style: TextStyle(color: Colors.white))),
      );

      Session? s = await _sessionService.createSession(
          _begin!.toUtc(),
          _end!.toUtc(),
          place,
          _kind,
          title,
          description,
          speakersIds,
          companyId,
          videoURL,
          sessionTickets);

      if (s != null) {
        SessionsNotifier notifier =
            Provider.of<SessionsNotifier>(context, listen: false);
        notifier.add(s);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                _sessionService.deleteSession(s.id);
                notifier.remove(s);
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

  Widget _buildForm() {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(children: [
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
                controller: _descriptionController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  icon: const Icon(Icons.description),
                  labelText: "Description *",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FormBuilderDateTimePicker(
                name: 'beginDate',
                controller: _beginDateController,
                validator: (value) {
                  if (value == null) {
                    return 'Please enter a beggining date';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  icon: const Icon(Icons.calendar_today),
                  labelText: "Begin Date *",
                ),
                onChanged: (value) => {_begin = value},
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FormBuilderDateTimePicker(
                name: 'endDate',
                controller: _endDateController,
                validator: (value) {
                  if (value == null) {
                    return 'Please enter an ending date';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  icon: const Icon(Icons.calendar_today),
                  labelText: "End Date *",
                ),
                onChanged: (value) => {_end = value},
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FormBuilderDropdown(
                  name: 'kind',
                  validator: (value) {
                    if (value == null) {
                      return 'Please enter the kind of session';
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
                    setState(() => _kind = newValue.toString());
                  }),
            ),
            Padding(
              padding: (_kind == "Talk")
                  ? const EdgeInsets.all(8.0)
                  : EdgeInsets.all(0),
              child: (_kind == "Talk")
                  ? DropdownSearch<Speaker>.multiSelection(
                      asyncItems: (String) => speakerService.getSpeakers(),
                      itemAsString: (Speaker u) => u.speakerAsString(),
                      popupProps: PopupPropsMultiSelection.menu(
                        showSearchBox: true,
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: const InputDecoration(
                          icon: const Icon(Icons.star),
                          labelText: "Speaker *",
                        ),
                      ),
                      validator: (value) {
                        if (_kind == "Talk") {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a speaker';
                          }
                          return null;
                        }
                        return null;
                      },
                      onChanged: (List<Speaker> speakers) {
                        speakersIds.clear();
                        for (var speaker in speakers) {
                          speakersIds.add(speaker.id);
                        }
                      },
                      clearButtonProps: ClearButtonProps(isVisible: true),
                    )
                  : null,
            ),
            Padding(
              padding: (_kind == "Workshop" || _kind == "Presentation")
                  ? const EdgeInsets.all(8.0)
                  : EdgeInsets.all(0),
              child: (_kind == "Workshop" || _kind == "Presentation")
                  ? DropdownSearch<Company>(
                      asyncItems: (String) => companyService.getCompanies(),
                      itemAsString: (Company u) => u.companyAsString(),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: const InputDecoration(
                          icon: const Icon(Icons.business),
                          labelText: "Company *",
                        ),
                      ),
                      validator: (value) {
                        if (_kind == "Workshop" || _kind == "Presentation") {
                          if (value == null) {
                            return 'Please enter a company';
                          }
                          return null;
                        }
                        return null;
                      },
                      onChanged: (Company? company) {
                        companyId = company!.id;
                      },
                      clearButtonProps: ClearButtonProps(isVisible: true),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.place),
                  labelText: "Place ",
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _videoURLController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.video_call),
                  labelText: "VideoURL ",
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      color: Color.fromARGB(255, 124, 123, 123),
                      size: 25.0,
                    ),
                    Text(
                      "Add tickets ",
                      style: TextStyle(
                          fontSize: 17.0,
                          color: Color.fromARGB(255, 102, 101, 101)),
                      textAlign: TextAlign.right,
                    ),
                    Switch(
                      onChanged: (bool value) {
                        setState(() {
                          _ticketsOn = value;
                        });
                      },
                      value: _ticketsOn,
                      activeColor: Color.fromARGB(255, 19, 214, 77),
                      activeTrackColor: Color.fromARGB(255, 97, 233, 138),
                      inactiveThumbColor: Color.fromARGB(255, 216, 30, 30),
                      inactiveTrackColor: Color.fromARGB(255, 245, 139, 139),
                    ),
                  ],
                )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: (_ticketsOn == true)
                  ? Row(
                      children: [
                        Text(
                          "Maximum number of tickets *",
                          style: TextStyle(
                              fontSize: 17.0,
                              color: Color.fromARGB(255, 102, 101, 101)),
                          textAlign: TextAlign.right,
                        ),
                        Slider(
                          value: _currentTicketsValue,
                          max: 100,
                          divisions: 100,
                          label: _currentTicketsValue.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _currentTicketsValue = value;
                            });
                          },
                        ),
                      ],
                    )
                  : null,
            ),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: (_ticketsOn == true)
                    ? FormBuilderDateTimePicker(
                        name: 'ticketBeginDate',
                        controller: _ticketBeginDateController,
                        validator: (value) {
                          if (value == null) {
                            return 'Please enter a beggining date for ticket availability';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          icon: const Icon(Icons.calendar_today),
                          labelText: "Ticket availability begin date *",
                        ),
                        onChanged: (value) => {_beginTicket = value},
                      )
                    : null),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: (_ticketsOn == true)
                    ? FormBuilderDateTimePicker(
                        name: 'ticketEndDate',
                        controller: _ticketEndDateController,
                        validator: (value) {
                          if (value == null) {
                            return 'Please enter an end date for ticket availability ';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          icon: const Icon(Icons.calendar_today),
                          labelText: "Ticket availability end date *",
                        ),
                        onChanged: (value) => {_endTicket = value},
                      )
                    : null),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _submit(),
                child: const Text('Submit'),
              ),
            ),
          ]),
        ));
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
