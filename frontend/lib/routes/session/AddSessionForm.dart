import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddSessionForm extends StatefulWidget {
  AddSessionForm({Key? key}) : super(key: key);

  @override
  _AddSessionFormState createState() => _AddSessionFormState();
}

const kinds = ["Talk", "Presentation", "Workshop"];
const List<Widget> ticketOptions = <Widget>[Text('Yes'), Text('No')];

class _AddSessionFormState extends State<AddSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _beginDateController = TextEditingController();
  final _endDateController = TextEditingController();
  var _speakerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _companyController = TextEditingController();
  final _videoURLController = TextEditingController();
  final _maxTicketsController = TextEditingController();
  final _ticketBeginDateController = TextEditingController();
  final _ticketEndDateController = TextEditingController();
  final _sessionService = SessionService();

  late Future<List<Speaker>> speakers;

  SpeakerService speakerService = new SpeakerService();

  DateTime? dateTime;
  DateTime? _begin;
  DateTime? _end;

  String _kind = "";
  bool value = false;
  final List<bool> _ticketSelection = <bool>[false, true];
  bool _yes = false;
  double _currentSliderValue = 0;
  bool _ticketsOn = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var title = _titleController.text;
      var place = _placeController.text;
      var speaker = _speakerController.text;
      var description = _descriptionController.text;
      var company = _companyController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading')),
      );

      List<String> speakersIds = [speaker];

      Session? s = await _sessionService.createSession(
          _begin!.toUtc(),
          _end!.toUtc(),
          place,
          _kind,
          title,
          description,
          speakersIds,
          company);
      if (s != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HERE')),
        );
        SessionsNotifier notifier =
            Provider.of<SessionsNotifier>(context, listen: false);
        notifier.add(s);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BL')),
        );
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occured.')),
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
                })),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: (_kind == "Talk")
              ? TextFormField(
                  controller: _speakerController,
                  validator: (value) {
                    if (_kind == "Talk") {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a speaker';
                      }
                      return null;
                    }
                  },
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.star),
                    labelText: "Speaker *",
                  ),
                  onChanged: (newQuery) {
                    setState(() {});
                    if (_speakerController.text.length > 1) {
                      this.speakers = speakerService.getSpeakers(
                          name: _speakerController.text);
                    }
                  })
              : null,
        ),
        ...getResults(MediaQuery.of(context).size.height / 3),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: (_kind == "Workshop" || _kind == "Presentation")
              ? TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.business),
                    labelText: "Company *",
                  ),
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
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: Column(
        //     children: [
        //       TextField(
        //         decoration: const InputDecoration(
        //             icon: const Icon(Icons.airplane_ticket),
        //             labelText: "Add tickets to this session"),
        //       ),
        //       Text('Add tickets'),
        //       const SizedBox(height: 5),
        //       ToggleButtons(
        //         onPressed: (int index) {
        //           setState(() {
        //             // The button that is tapped is set to true, and the others to false.
        //             for (int i = 0; i < _ticketSelection.length; i++) {
        //               _ticketSelection[i] = i == index;
        //               _yes = i != index;
        //             }
        //           });
        //         },
        //         borderRadius: const BorderRadius.all(Radius.circular(8)),
        //         selectedBorderColor: Color.fromARGB(255, 63, 81, 181),
        //         selectedColor: Color.fromARGB(255, 63, 81, 181),
        //         fillColor: Color.fromARGB(255, 150, 164, 243),
        //         color: Color.fromARGB(255, 0, 0, 0),
        //         constraints: const BoxConstraints(
        //           minHeight: 40.0,
        //           minWidth: 80.0,
        //         ),
        //         isSelected: _ticketSelection,
        //         children: ticketOptions,
        //       ),
        //       Text(
        //         'Add tickets to this session',
        //         //style: TextStyle(fontSize: 17.0),
        //       ),
        //       // SizedBox(width: 10), //SizedBox
        //       Checkbox(
        //         value: this.value,
        //         onChanged: (value) {
        //           setState(() {
        //             this.value = value!;
        //           });
        //         },
        //       ),
        //     ],
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: (_ticketsOn == true)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Maximum number of tickets *",
                      style: TextStyle(fontSize: 17.0),
                      textAlign: TextAlign.right,
                    ),
                    Slider(
                      value: _currentSliderValue,
                      max: 100,
                      divisions: 100,
                      label: _currentSliderValue.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _currentSliderValue = value;
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
                ? TextFormField(
                    controller: _ticketBeginDateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a beggining date for ticket availability *';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.calendar_today),
                      labelText: "Ticket availability begin date *",
                    ),
                    readOnly:
                        true, //prevents editing the date in the form field
                    onTap: () async {
                      await _selectDateTime(context, true);
                      String formattedDate = getDateTime(_begin!);
                      setState(() {
                        _beginDateController.text = formattedDate;
                      });
                    },
                  )
                : null),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: (_ticketsOn == true)
                ? TextFormField(
                    controller: _ticketBeginDateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an end date for ticket availability *';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.calendar_today),
                      labelText: "Ticket availability end date *",
                    ),
                    readOnly:
                        true, //prevents editing the date in the form field
                    onTap: () async {
                      await _selectDateTime(context, true);
                      String formattedDate = getDateTime(_begin!);
                      setState(() {
                        _beginDateController.text = formattedDate;
                      });
                    },
                  )
                : null),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  "Add tickets *",
                  style: TextStyle(fontSize: 17.0),
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
          child: ElevatedButton(
            onPressed: () => _submit(),
            child: const Text('Submit'),
          ),
        ),
      ]),
    );
  }

  List<Widget> getResults(double height) {
    if (_speakerController.text.length > 1) {
      return [
        Container(
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: FutureBuilder(
                future: Future.wait([this.speakers]),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<dynamic> data = snapshot.data as List<dynamic>;

                    List<Speaker> speaksMatched = data[0] as List<Speaker>;
                    return searchResults(speaksMatched, height);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                }))
      ];
    } else {
      return [];
    }
  }

  Widget searchResults(List<Speaker> speakers, double listHeight) {
    List<Widget> results = getListCards(speakers);
    return Container(
        constraints: BoxConstraints(maxHeight: listHeight),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (BuildContext context, int index) {
              return results[index];
            }));
  }

  List<Widget> getListCards(List<Speaker> speakers) {
    List<Widget> results = [];
    if (speakers.length != 0) {
      results.addAll(speakers
          .map((e) => SpeakerSearch(speaker: e, index: speakers.indexOf(e))));
    }
    return results;
  }

  SpeakerSearch({required Speaker speaker, required int index}) {
    return InkWell(
        onTap: () {
          _speakerController.text = speaker.id;
          setState(() {});
        },
        child: Center(
          child: ListTile(
            leading: CircleAvatar(
              foregroundImage: NetworkImage(getImageURL(speaker)),
              backgroundImage: AssetImage(
                'assets/noImage.png',
              ),
            ),
            title: Text(getName(speaker)),
          ),
        ));
  }

  String getImageURL(Speaker speaker) {
    if (speaker != null) {
      return speaker!.imgs!.internal!;
    } else {
      //ERROR case
      return "";
    }
  }

  String getName(Speaker speaker) {
    if (speaker != null) {
      return speaker!.name;
    } else {
      //ERROR case
      return "";
    }
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
