import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/services/contactService.dart';

class EditableComponent2 extends StatelessWidget {
  final int index;
  final String type;
  final Contact contact;

  EditableComponent2(
      {Key? key,
      required this.index,
      required this.contact,
      required this.type})
      : super(key: key);
      

  @override
  Widget build(BuildContext context) {
    if (type == "mail") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SelectableText(
            contact.mails![index].mail!,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          Row(
            children: [
              contact.mails![index].valid!
                  ? Container()
                  : Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: Icon(Icons.report, color: Colors.red[300]),
                    ),
              contact.mails![index].personal!
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: Icon(Icons.house),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: Icon(Icons.work),
                    ),
            ],
          )
        ],
      );
    } else if (type == "phone") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SelectableText(
            contact.phones![index].phone!,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              contact.phones![index].valid!
                  ? Container()
                  : Icon(
                      Icons.report,
                      color: Colors.red[300],
                    ),
            ],
          )
        ],
      );
    } else {
      return Text("");
    }
      
    
  }
}
