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

class _AddThreadFormState extends State<AddThreadForm> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
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
    int event = Provider.of<EventNotifier>(context).event.id;
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
                    selectedTemplateId = selectedTemplateId ?? templates.first.id;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField<String>(
                            icon: Icon(Icons.tag),
                            items: templates
                                .map((e) =>
                                    DropdownMenuItem<String>(value: e.id, child: Text(e.name)))
                                .toList(),
                            value: templates.first.id,
                            selectedItemBuilder: (BuildContext context) {
                              return templates.map((e) {
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _submit(context),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
