import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/speaker.dart';

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
  String kind = 'TEMPLATE';

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

  @override
  Widget build(BuildContext context) {
    List<String> kinds = ["TEMPLATE", "TO", "FROM", "PHONE_CALL", "MEETING"];
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
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
