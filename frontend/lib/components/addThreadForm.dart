import 'package:flutter/material.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:frontend/services/speakerService.dart';

class AddThreadForm extends StatefulWidget {
  final Speaker? speaker;
  final Company? company;
  final Meeting? meeting;
  final void Function(BuildContext, Speaker?)? onEditSpeaker;
  final void Function(BuildContext, Company?)? onEditCompany;
  final void Function(BuildContext, Meeting?)? onEditMeeting;
  AddThreadForm(
      {Key? key,
      this.speaker,
      this.company,
      this.meeting,
      this.onEditSpeaker,
      this.onEditCompany,
      this.onEditMeeting})
      : super(key: key);

  @override
  _AddThreadFormState createState() => _AddThreadFormState();
}

class _AddThreadFormState extends State<AddThreadForm> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  String kind = '';

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      var text = _textController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading')),
      );
      if (widget.speaker != null && widget.onEditSpeaker != null) {
        SpeakerService service = SpeakerService();
        Speaker? s = await service.addThread(
            id: widget.speaker!.id, text: text, kind: kind);
        if (s != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Done'),
              duration: Duration(seconds: 2),
            ),
          );
          widget.onEditSpeaker!(context, s);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occured.')),
          );
        }
      } else if (widget.company != null && widget.onEditCompany != null) {
        CompanyService service = CompanyService();
        Company? s = await service.addThread(
            id: widget.speaker!.id, text: text, kind: kind);
        if (s != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Done'),
              duration: Duration(seconds: 2),
            ),
          );
          widget.onEditCompany!(context, s);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occured.')),
          );
        }
      } else if (widget.meeting != null && widget.onEditMeeting != null) {
        MeetingService service = MeetingService();
        Meeting? m = await service.addThread(
            id: widget.meeting!.id, kind: 'MEETING', text: text);
        if (m != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Done'),
              duration: Duration(seconds: 2),
            ),
          );
          widget.onEditMeeting!(context, m);

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occured.')),
          );

          Navigator.pop(context);
        }
      }
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
          if (widget.meeting == null && widget.onEditMeeting == null)
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
