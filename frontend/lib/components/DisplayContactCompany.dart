import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/components/EditContact.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/contactService.dart';
import 'package:provider/provider.dart';
import 'InformationBox.dart';

class DisplayContactsCompany extends StatefulWidget {
  final CompanyRep rep;

  DisplayContactsCompany({Key? key, required this.rep}) : super(key: key);

  @override
  _DisplayContactsState createState() => _DisplayContactsState();
}

class _DisplayContactsState extends State<DisplayContactsCompany> {
  ContactService contactService = new ContactService();
  late Future<Contact?> contact;

  @override
  void initState() {
    super.initState();
    this.contact = contactService.getContact(widget.rep.contactID);
  }

  _isEditable(Contact cont) {
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;

            if (r == Role.ADMIN || r == Role.COORDINATOR || r == Role.MEMBER) {
              return FloatingActionButton.extended(
                onPressed: () async {
                  final bool? shouldRefresh = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditContact(contact: cont, person: widget.rep),
                    ),
                  );
                  if (shouldRefresh ?? false) {
                    this.contact =
                        contactService.getContact(widget.rep.contactID);
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
            appBar: AppBar(
              title: Text('Contact Details'),
              backgroundColor: Color(0xff5C7FF2),
            ),
            backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEFEFEF), Color(0xFFFFFFFF)],
                ),
              ),
              child: ListView(
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
            ),
            floatingActionButton: _isEditable(cont),
          );
        } else {
          return Container(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      });
}
