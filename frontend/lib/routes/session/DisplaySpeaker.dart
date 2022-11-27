import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/member/EditContact.dart';
import 'package:frontend/routes/session/SessionInformationBox.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/contactService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';

class DisplaySpeakers extends StatefulWidget {
  final Session session;
  const DisplaySpeakers({Key? key, required this.session}) : super(key: key);

  @override
  _DisplayTicketsState createState() => _DisplayTicketsState();
}

class _DisplayTicketsState extends State<DisplaySpeakers> {
  ContactService contactService = new ContactService();
  SpeakerService speakerService = new SpeakerService();
  List<Speaker> allSpeakers = [];

  // late Future<Contact?> contact;

  @override
  void initState() {
    super.initState();
    fillSpeakers();

    // this.contact = contactService.getContact(widget.member.contact!);
  }

  Future<void> fillSpeakers() async {
    Future<List<Speaker>> speakersFuture = speakerService.getSpeakers();

    allSpeakers = await speakersFuture;
  }

  List<String> _getSpeakers(List<String>? ids) {
    List<String> speakersNames = [];
    for (var speaker in allSpeakers) {
      for (var id in ids!) {
        if (speaker.id == id && (!speakersNames.contains(speaker.name))) {
          speakersNames.add(speaker.name);
        }
      }
    }
    return speakersNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          (widget.session.tickets == null)
              ? NoTicketsAvailable(widget.session)
              : TicketsAvailable(widget.session),

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

  Widget NoTicketsAvailable(Session session) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
                blurRadius: 7.0,
                color: Colors.grey.withOpacity(0.3),
                offset: new Offset(0, 3),
                spreadRadius: 4.0),
          ]),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Not Available",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "No tickets were made available for this session.",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            )
          ],
        ),
      ]),
    );
  }

  Widget TicketsAvailable(Session session) {
    return Column(
      children: [
        SessionInformationBox(session: widget.session, type: "Max Tickets"),
        SessionInformationBox(session: widget.session, type: "Start Tickets"),
        SessionInformationBox(session: widget.session, type: "End Tickets"),
      ],
    );
  }
}
