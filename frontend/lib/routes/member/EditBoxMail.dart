import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/routes/member/EditableComponentMail.dart';
import 'package:frontend/services/contactService.dart';

class EditBoxMail extends StatefulWidget {
  final String title;
  final String memberId;
  List<ContactMail> mails;

  EditBoxMail(
      {Key? key,
      required this.title,
      required this.memberId,
      required this.mails})
      : super(key: key);

  @override
  _EditBoxState createState() => _EditBoxState();
}

class _EditBoxState extends State<EditBoxMail> {

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
            for (int i = 0; i < widget.mails.length; i++)
              EditableComponentMail(index: i, memberId: widget.memberId, mail: widget.mails[i].mail!),
          ],
        ),
      ]),
    );
  }
}
