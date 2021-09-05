import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/contactService.dart';

class EditableComponentPhone extends StatefulWidget {
  final int index;
  final String memberId;
  String phone;
  EditableComponentPhone({Key? key, required this.index, required this.memberId, required this.phone})
      : super(key: key);

  @override
  _EditableComponentPhoneState createState() => _EditableComponentPhoneState();
}

class _EditableComponentPhoneState extends State<EditableComponentPhone> {
  ContactService contactService = new ContactService();
  TextEditingController _textFieldController = TextEditingController();

  _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Change Mail'),
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
                    //TODO: mudar
                    widget.phone = _textFieldController.text;
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
    return  Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectableText(
              widget.phone,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            IconButton(
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
            ],
    );
  }
}
