import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/contactService.dart';
import 'package:frontend/routes/member/EditBox.dart';
import 'package:frontend/routes/member/EditBoxSocials.dart';

class DisplayContacts extends StatefulWidget {
  final Member member;
  const DisplayContacts({Key? key, required this.member}) : super(key: key);

  @override
  _DisplayContactsState createState() => _DisplayContactsState();
}

class _DisplayContactsState extends State<DisplayContacts> {
  ContactService contactService = new ContactService();
  late Future<Contact?> contact;
  String phones = "";
  String mails = "";
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

          print(cont.mails!.length);

          if (cont.mails!.length > 0) {
            for (int i = 0; i < cont.mails!.length; i++) {
              mails += cont.mails![i].mail!;
              if (i < cont.mails!.length - 1) mails += "\n";
            }
          }

          if (cont.phones!.length > 0) {
            for (int i = 0; i < cont.phones!.length; i++) {
              phones += cont.phones![i].phone!;
              if (i < cont.mails!.length - 1) mails += "\n";
            }
          }

          if (cont.socials!.facebook != null) {
            facebook = cont.socials!.facebook!;
          }

          if (cont.socials!.github != null) {
            github = cont.socials!.github!;
          }

          if (cont.socials!.linkedin != null) {
            linkedin = cont.socials!.linkedin!;
          }

          if (cont.socials!.skype != null) {
            skype = cont.socials!.skype!;
          }

          if (cont.socials!.twitter != null) {
            twitter = cont.socials!.twitter!;
          }

          return Column(
            children: [
              //Text("${cont.mails!.length}"),
              EditBox(title: "Mails", body: mails),
              EditBox(title: "Phone", body: phones),

              EditBoxSocials(title: "Others", facebook: facebook, github: github, 
              twitter: twitter, skype: skype, linkedin: linkedin),
            ],
          );
        } else {
          //FIXME: change
          return CircularProgressIndicator();
        }
      });
}
