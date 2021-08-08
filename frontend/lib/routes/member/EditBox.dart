import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/contactService.dart';

class EditBox extends StatefulWidget {
  final String title;
  String body;
  EditBox({Key? key, required this.title, required this.body})
      : super(key: key);

  @override
  _EditBoxState createState() => _EditBoxState();
}

class _EditBoxState extends State<EditBox> {
  ContactService contactService = new ContactService();
  TextEditingController _textFieldController = TextEditingController();

  _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Change ${widget.title}'),
            content: TextField(
              controller: _textFieldController,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  _textFieldController.clear();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: new Text('Save'),
                onPressed: () {
                  setState(() {
                    widget.body = _textFieldController.text;
                  });
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5)),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            Divider(),
            SelectableText(
              widget.body,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 18, color: Colors.black),
            )
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              icon: Icon(Icons.edit),
              color: Color.fromRGBO(211, 211, 211, 1),
              iconSize: 18,
              onPressed: () {
                _displayDialog(context);
              }),
        )
      ]),
    );
  }
}
