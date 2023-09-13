import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/requirement.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/template.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/templateService.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

class AddThreadForm extends StatefulWidget {
  final Speaker? speaker;
  final Company? company;
  final Meeting? meeting;
  final void Function(String, String)? onAddSpeaker;
  final void Function(String, String)? onAddCompany;
  final void Function(String)? onAddMeeting;
  AddThreadForm(
      {Key? key,
      this.speaker,
      this.company,
      this.meeting,
      this.onAddSpeaker,
      this.onAddCompany,
      this.onAddMeeting})
      : super(key: key);

  @override
  _AddThreadFormState createState() => _AddThreadFormState();
}

String ordinal(int number) {
    if(!(number >= 1 && number <= 100)) {//here you change the range
      throw Exception('Invalid number');
    }

    if(number >= 11 && number <= 13) {
      return 'th';
    }

    switch(number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
}

class _AddThreadFormState extends State<AddThreadForm> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _paragraphController = TextEditingController();
  final TemplateService templateService = TemplateService();
  final AuthService authService = new AuthService();
  String kind = 'TEMPLATE';
  String? selectedTemplateId;
  late Future<List<Template>> _templates;

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      var text = _textController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Uploading', style: TextStyle(color: Colors.white))),
      );

      if (widget.speaker != null && widget.onAddSpeaker != null) {
        widget.onAddSpeaker!(text, kind);
      } else if (widget.company != null && widget.onAddCompany != null) {
        widget.onAddCompany!(text, kind);
      } else if (widget.meeting != null && widget.onAddMeeting != null) {
        widget.onAddMeeting!(text);
      }
      Navigator.pop(context);
    }
  }

  void _getTemplate(BuildContext context) async {
    Member me = Provider.of<Member?>(context, listen: false)!;
    int eventEdition = Provider.of<EventNotifier>(context, listen: false).event.id;
    List<Requirement> filledRequirements = [];

    if (_formKey.currentState!.validate()) {
      (await _templates).forEach((template) {
        if (template.id == selectedTemplateId) {
          template.requirements?.forEach((req) {
            switch (req.name) {
              case "speakerName" :
                req.stringVal = widget.speaker!.name;
                break;
              case "userName" :
                req.stringVal = me.name;
                break;
              case "companyName" :
                req.stringVal = widget.company!.name;
                break;
              case "eventEdition" :
                req.stringVal = eventEdition.toString();
                break;
              case "eventEditionOrdinal" :
                req.stringVal = ordinal(eventEdition);
                break;
              case "initialParagraph" :
                req.stringVal = _paragraphController.text;
                break;
              case "eventDates" :
                DateTime eventStart = Provider.of<EventNotifier>(context, listen: false).event.start;
                DateTime eventEnd = Provider.of<EventNotifier>(context, listen: false).event.end;
                String dateStart ="${eventStart.day.toString().padLeft(2,'0')}/${eventStart.month.toString().padLeft(2,'0')}/${eventStart.year.toString()}";
                String dateEnd ="${eventEnd.day.toString().padLeft(2,'0')}/${eventEnd.month.toString().padLeft(2,'0')}/${eventEnd.year.toString()}";
                req.stringVal = dateStart + " - " + dateEnd;
            }
            filledRequirements.add(req);
          });
        }
      });

      if(selectedTemplateId != null){
        var uuid = await templateService.fillTemplate(id:selectedTemplateId!, filledRequirements: filledRequirements);
        if(uuid != null){
          final String? _deckURL =
            kIsWeb ? dotenv.env['DECK2_URL'] : dotenv.env['DECK2_MOBILE_URL'];
          String filteredUuid = uuid.replaceAll('"', '');
          html.window.open(_deckURL! + "/templates/filled/" + filteredUuid ,"_blank");
        }
      }

      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _templates = templateService.getTemplates();
  }


  @override
  Widget build(BuildContext context) {
    List<String> kinds = ["TEMPLATE", "TO", "FROM", "PHONE_CALL", "MEETING"];
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (widget.meeting == null && widget.onAddMeeting == null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                icon: Icon(Icons.tag),
                items: kinds
                    .map((e) =>
                        DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList(),
                value: kinds[0],
                selectedItemBuilder: (BuildContext context) {
                  return kinds.map((e) {
                    return Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(child: Text(e)),
                    );
                  }).toList();
                },
                onChanged: (next) {
                  setState(() {
                    kind = next!;
                  });
                },
              ),
            ),
          Visibility(
            visible: kind != "TEMPLATE",
            child: Padding(
              padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: null,
                  controller: _textController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please contents of communication';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.work),
                    labelText: "Content *",
                  ),
                ),
              ),
          ),
          Visibility(
            visible: kind == "TEMPLATE",
            child: FutureBuilder(
              future: _templates,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Template> templates = snapshot.data as List<Template>;
                  if (!templates.isEmpty) {
                    var validTemplates = templates.where((template) {
                      if (widget.speaker != null) return template.kind == "Speaker";
                      else if (widget.company != null) return template.kind == "Company";
                      else return false;
                    });
                    selectedTemplateId = selectedTemplateId ?? validTemplates.first.id;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<String>(
                            icon: Icon(Icons.tag),
                            items: validTemplates
                                .map((e) =>
                                    DropdownMenuItem<String>(value: e.id, child: Text(e.name)))
                                .toList(),
                            value: validTemplates.first.id,
                            selectedItemBuilder: (BuildContext context) {
                              return validTemplates.map((e) {
                                return Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Container(child: Text(e.name)),
                                );
                              }).toList();
                            },
                            onChanged: (next) {
                              setState(() {
                                selectedTemplateId = next!;
                              });
                            },
                          ),
                        ),
                        Visibility(
                          visible: templates.firstWhere((template) => template.id == selectedTemplateId)
                              .requirements!.any((req) => req.name == "initialParagraph"),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              controller: _paragraphController,
                              maxLines: null,
                              decoration: const InputDecoration(
                                icon: const Icon(Icons.work),
                                labelText: "Insert initial paragraph (optional)",
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () => _getTemplate(context),
                            child: const Text('Get Template'),
                          ),
                        ),
                      ]
                    );
                  }
                  else {
                  return Container();
                }
                } else {
                  return Container();
                }
              }),
          ),
          // This is temporary, while templates are not editable, to prevent users from submitting an empty thread.
          Visibility(
            visible: kind != "TEMPLATE",
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _submit(context),
                child: const Text('Submit'),
              )
            )
          )
        ],
      ),
    );
  }
}
