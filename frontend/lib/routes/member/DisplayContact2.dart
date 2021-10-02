import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/member/EditContact2.dart';
import 'package:frontend/services/contactService.dart';
import 'package:frontend/routes/member/EditBox.dart';
import 'package:frontend/routes/member/EditBoxSocials.dart';

import 'EditContact.dart';
import 'InformationBox.dart';

class DisplayContacts2 extends StatefulWidget {
  final Member member;
  const DisplayContacts2({Key? key, required this.member}) : super(key: key);

  @override
  _DisplayContactsState createState() => _DisplayContactsState();
}

class _DisplayContactsState extends State<DisplayContacts2> {
  ContactService contactService = new ContactService();
  late Future<Contact?> contact;
  String socials = "";
  String facebook = "";
  String twitter = "";
  String github = "";
  String skype = "";
  String linkedin = "";

  @override
  void initState() {
    super.initState();
    this.contact = contactService.getContact(widget.member.contact!);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: contact,
      builder: (context, snapshot) {
        print(snapshot.hasData);
        if (snapshot.hasData) {
          Contact cont = snapshot.data as Contact;

          return Column(
            children: [
              InformationBox(title: "Mails", contact: cont, type: "mail"),
              InformationBox(title: "Phones", contact: cont, type: "phone"),
              InformationBox(title: "Socials", contact: cont, type: "social"),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).accentColor,
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditContact2(contact: cont, member: widget.member)),
                    );
                  },
                  child: const Text('EDIT CONTACTS'),
                ),
              ),
              //SizedBox(height: 24,),
              
            ],
          );
        } else {
          //FIXME: change
          return CircularProgressIndicator();
        }
      });
}
