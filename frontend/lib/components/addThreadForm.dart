import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/companyService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:image_picker/image_picker.dart';

class AddThreadForm extends StatefulWidget {
  final Speaker? speaker;
  final Company? company;
  final void Function(BuildContext, Speaker?) onEdit;
  AddThreadForm({Key? key, this.speaker, this.company, required this.onEdit})
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
      if (widget.speaker != null) {
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
          widget.onEdit(context, s);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occured.')),
          );
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              icon: Icon(Icons.tag),
              items: kinds
                  .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
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
