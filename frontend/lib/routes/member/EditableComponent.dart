import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/services/contactService.dart';

class EditableComponent extends StatefulWidget {
  final int index;
  final String memberId;
  final String type;
  Contact contact;

  EditableComponent(
      {Key? key,
      required this.index,
      required this.memberId,
      required this.contact,
      required this.type})
      : super(key: key);

  @override
  _EditableComponentState createState() => _EditableComponentState();
}

class _EditableComponentState extends State<EditableComponent> {
  ContactService contactService = new ContactService();
  TextEditingController _textFieldController = TextEditingController();

  _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
                'Change ${widget.type[0].toUpperCase()}${widget.type.substring(1)}'),
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
                  updateContact(_textFieldController.text);
                  _textFieldController.clear();
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == "mail") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SelectableText(
            widget.contact.mails![widget.index].mail!,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          Row(
            children: [
              widget.contact.mails![widget.index].valid!
                  ? Container()
                  : Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: Icon(Icons.report, color: Colors.red[300]),
                    ),
              widget.contact.mails![widget.index].personal!
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: Icon(Icons.house),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: Icon(Icons.work),
                    ),
              IconButton(
                  padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
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
          )
        ],
      );
    } else if (widget.type == "phone") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SelectableText(
            widget.contact.phones![widget.index].phone!,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              widget.contact.phones![widget.index].valid!
                  ? Container()
                  : Icon(
                      Icons.report,
                      color: Colors.red[300],
                    ),
              IconButton(
                  padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
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
          )
        ],
      );
    } else {
      return Text("");
    }
  }

  updateContact(String text) async {
    //ContactService contactService = new ContactService();

    if (widget.type == "mail") {
      var newListContactMail = List<ContactMail>.empty(growable: true);

      for (int i = 0; i < widget.contact.mails!.length; i++) {
        newListContactMail.add(new ContactMail(
            mail: i == widget.index ? text : widget.contact.mails![i].mail,
            personal: widget.contact.mails![i].personal,
            valid: widget.contact.mails![i].valid));
      }

      await ContactService().updateContact(new Contact(
          id: widget.contact.id,
          phones: widget.contact.phones,
          socials: widget.contact.socials,
          mails: newListContactMail)
          );
    }

    else if(widget.type == "phone"){
      var newListContactPhone = List<ContactPhone>.empty(growable: true);

      for (int i = 0; i < widget.contact.phones!.length; i++) {
        newListContactPhone.add(new ContactPhone(
            phone: i == widget.index ? text : widget.contact.phones![i].phone,
            valid: widget.contact.mails![i].valid));
      }

      await ContactService().updateContact(new Contact(
          id: widget.contact.id,
          phones: newListContactPhone,
          socials: widget.contact.socials,
          mails: widget.contact.mails)
          );
    }
  }
}
