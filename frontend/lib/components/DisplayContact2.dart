import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/components/EditContact.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/contactService.dart';
import 'package:provider/provider.dart';
import 'InformationBox.dart';

class DisplayContacts extends StatefulWidget {
  final dynamic person; // Accept either Speaker or Member
  const DisplayContacts({Key? key, required this.person}) : super(key: key);

  @override
  _DisplayContactsState createState() => _DisplayContactsState();
}

class _DisplayContactsState extends State<DisplayContacts> {
  ContactService contactService = new ContactService();
  late Future<Contact?> contact;

  @override
  void initState() {
    super.initState();
    this.contact = contactService.getContact(widget.person.contact!);
  }

  _isEditable(Contact cont) {
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;
            Member me = Provider.of<Member?>(context)!;

            if (r == Role.ADMIN ||
                r == Role.COORDINATOR ||
                r == Role.MEMBER ||
                (widget.person is Member && widget.person.id == me.id)) {
              return FloatingActionButton.extended(
                onPressed: () async {
                  final bool? shouldRefresh = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditContact(contact: cont, person: widget.person)),
                  );
                  if (shouldRefresh ?? false) {
                    this.contact =
                        contactService.getContact(widget.person.contact!);
                    setState(() {});
                  }
                },
                label: const Text('Edit Contacts'),
                icon: const Icon(Icons.edit),
                backgroundColor: Color(0xff5C7FF2),
              );
            } else
              return Container();
          } else
            return Container();
        });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: contact,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Contact cont = snapshot.data as Contact;
          return Scaffold(
            backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
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
            floatingActionButton: _isEditable(cont),
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
