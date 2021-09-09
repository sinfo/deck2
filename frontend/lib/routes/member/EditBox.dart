import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/routes/member/EditableComponent.dart';
import 'package:frontend/services/contactService.dart';

class EditBox extends StatefulWidget {
  final String title;
  final String memberId;
  final String type;
  int length = 0;
  Contact contact;

  EditBox(
      {Key? key,
      required this.title,
      required this.memberId,
      required this.contact,
      required this.type})
      : super(key: key);

  @override
  _EditBoxState createState() => _EditBoxState();
}

class _EditBoxState extends State<EditBox> {
  @override
  Widget build(BuildContext context) {
    if (widget.type == "mail") {
      widget.length = widget.contact.mails!.length;
    } else if (widget.type == "phone") {
      widget.length = widget.contact.phones!.length;
    }

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
            for (int i = 0; i < widget.length; i++)
              EditableComponent(
                  index: i, memberId: widget.memberId, contact: widget.contact, type: widget.type),
          ],
        ),
      ]),
    );
  }
}
