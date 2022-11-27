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

class DisplaySpeaker extends StatefulWidget {
  final Session session;
  const DisplaySpeaker({Key? key, required this.session}) : super(key: key);

  @override
  _DisplaySpeaker createState() => _DisplaySpeaker();
}

class _DisplaySpeaker extends State<DisplaySpeaker> {
  ContactService contactService = new ContactService();
  SpeakerService speakerService = SpeakerService();
  List<Speaker> allSpeakers = [];

  // late Future<Contact?> contact;

  @override
  void initState() {
    super.initState();
    fillSpeakers();
  }

  Future<void> fillSpeakers() async {
    Future<List<Speaker>> speakersFuture = speakerService.getSpeakers();

    allSpeakers = await speakersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Speakers",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              Divider(),
              showSpeakers(session: widget.session),
            ],
          ),
        ],
      ),
      // floatingActionButton: _isEditable(cont),
    );
  }

  Widget showSpeakers({required Session session}) {
    List<String> speakersNames = [];
    for (var speaker in allSpeakers) {
      for (var id in session.speakersIds!) {
        if (speaker.id == id && (!speakersNames.contains(speaker.name))) {
          speakersNames.add(speaker.name);
        }
      }
    }
    return ListView.separated(
        itemBuilder: (BuildContext context, index) {
          return CircleAvatar(
            backgroundImage: NetworkImage(
                'https://media-exp1.licdn.com/dms/image/C4D03AQFgZBilNtPUMA/profile-displayphoto-shrink_800_800/0/1604728137407?e=1632960000&v=beta&t=QKa1Nq3WKWQGEGaiKdZ1ovp1h6uAbwPZfihdqY2_pNU'),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(
            width: 10,
          );
        },
        itemCount: speakersNames.length);
    // return Row(
    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //   children: [
    //     Text(
    //       info,
    //       textAlign: TextAlign.left,
    //       style: TextStyle(fontSize: 16, color: Colors.black),
    //     ),
    //   ],
    // );
  }
}
