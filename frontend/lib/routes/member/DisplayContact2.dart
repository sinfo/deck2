import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/member/EditContact.dart';
import 'package:frontend/services/contactService.dart';
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

  @override
  void initState() {
    super.initState();
    this.contact = contactService.getContact(widget.member.contact!);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: contact,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Contact cont = snapshot.data as Contact;

          return Scaffold(
            body: ListView(
              padding: EdgeInsets.symmetric(horizontal: 32),
              physics: BouncingScrollPhysics(),
              children: [
                InformationBox(title: "Mails", contact: cont, type: "mail"),
                InformationBox(title: "Phones", contact: cont, type: "phone"),
                InformationBox(
                    title: "Socials",
                    contact: cont,
                    type: "social"), //SizedBox(height: 24,),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditContact(contact: cont, member: widget.member)),
                );
              },
              label: const Text('Edit Contacts'),
              icon: const Icon(Icons.edit),
              backgroundColor: Color(0xff5C7FF2),
            ),
          );
        } else {
          return Container(
            child: Center(
              child: Container(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      });
}
