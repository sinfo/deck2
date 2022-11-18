import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/member/EditContact.dart';
import 'package:frontend/routes/session/SessionInformationBox.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/contactService.dart';
import 'package:provider/provider.dart';

class DisplayGeneralInformation extends StatefulWidget {
  final Session session;
  const DisplayGeneralInformation({Key? key, required this.session})
      : super(key: key);

  @override
  _DisplayGeneralInformation createState() => _DisplayGeneralInformation();
}

class _DisplayGeneralInformation extends State<DisplayGeneralInformation> {
  ContactService contactService = new ContactService();
  // late Future<Contact?> contact;

  @override
  void initState() {
    super.initState();
    // this.contact = contactService.getContact(widget.member.contact!);
  }

  // _isEditable(Contact cont) {
  //   return FutureBuilder(
  //       future: Provider.of<AuthService>(context).role,
  //       builder: (context, snapshot) {
  //         if (snapshot.hasData) {
  //           Role r = snapshot.data as Role;

  //           if (r == Role.ADMIN || r == Role.COORDINATOR) {
  //             return FloatingActionButton.extended(
  //               onPressed: () {
  //                 Navigator.pushReplacement(
  //                   context,
  //                   MaterialPageRoute(
  //                       builder: (context) =>
  //                           EditContact(contact: cont, member: widget.member)),
  //                 );
  //               },
  //               label: const Text('Edit Contacts'),
  //               icon: const Icon(Icons.edit),
  //               backgroundColor: Color(0xff5C7FF2),
  //             );
  //           } else
  //             return Container();
  //         } else
  //           return Container();
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          SessionInformationBox(session: widget.session, type: "kind"),
          SessionInformationBox(session: widget.session, type: "description"),
          SessionInformationBox(session: widget.session, type: "place"),
          SessionInformationBox(session: widget.session, type: "videoURL"),

          // InformationBox(title: "Phones", contact: cont, type: "phone"),
          // InformationBox(
          //     title: "Socials",
          //     contact: cont,
          //     type: "social"), //SizedBox(height: 24,),
        ],
      ),
      // floatingActionButton: _isEditable(cont),
    );
  }
}
