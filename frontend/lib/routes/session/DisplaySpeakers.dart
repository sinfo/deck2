import 'package:flutter/material.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/member/EditContact.dart';
import 'package:frontend/routes/session/SessionInformationBox.dart';
import 'package:frontend/routes/speaker/SpeakerScreen.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';

class DisplaySpeakers extends StatefulWidget {
  final Session session;
  const DisplaySpeakers({Key? key, required this.session}) : super(key: key);

  @override
  _DisplaySpeakersState createState() => _DisplaySpeakersState();
}

class _DisplaySpeakersState extends State<DisplaySpeakers> {
  SpeakerService speakerService = new SpeakerService();
  List<Speaker> allSpeakers = [];
  List<String> speakersNames = [];
  List<Images?> speakersImages = [];
  List<String?> speakersTitle = [];
  List<Speaker> speakers = [];

  @override
  void initState() {
    super.initState();
    fillSpeakers();
    // speakersNames = _getSpeakers(widget.session.speakersIds);
    print("22222222");

    print(speakersNames);
  }

  Future<void> fillSpeakers() async {
    Future<List<Speaker>> speakersFuture = speakerService.getSpeakers();

    allSpeakers = await speakersFuture;
    print("ALL SPEAKERS");
    print(allSpeakers);

    for (var speaker in allSpeakers) {
      print("Here");
      for (var id in widget.session.speakersIds!) {
        print("There");
        if (speaker.id == id && (!speakersNames.contains(speaker.name))) {
          print("ADDED");
          print(speaker.name);
          setState(() {
            speakersNames.add(speaker.name);
            speakersImages.add(speaker.imgs);
            speakersTitle.add(speaker.title);
            speakers.add(speaker);
          });
        } else {
          print("Ids are different.");
          print("Id from session: " + id);
          print("Id from speaker: " + speaker.id);
        }
      }
    }
  }

  List<String> _getSpeakers(List<String>? ids) {
    print("IDS");
    print(ids);
    print(allSpeakers);

    for (var speaker in allSpeakers) {
      print("Here");
      for (var id in ids!) {
        print("There");
        if (speaker.id == id && (!speakersNames.contains(speaker.name))) {
          print("ADDED");
          print(speaker.name);
          setState(() {
            speakersNames.add(speaker.name);
          });
        } else {
          print("Ids are different.");
          print("Id from session: " + id);
          print("Id from speaker: " + speaker.id);
        }
      }
    }
    print("11111");

    print(speakersNames);
    return speakersNames;
  }

  @override
  Widget build(BuildContext context) {
    print("##########################################");
    print(speakersNames);
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: new ListView.builder(
          itemCount: widget.session.speakersIds!.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
                child: ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SpeakerScreen(
                              speaker: speakers[index],
                            ))); //TODO
              },
              title: Text(speakersNames![index]),
              subtitle: Text(speakersTitle[index]!),
              leading: CircleAvatar(
                foregroundImage: NetworkImage(
                  speakersImages[index]!.speaker ??
                      (speakersImages[index]!.internal ??
                          (speakersImages[index]!.company ?? "")),
                ),
                backgroundImage: AssetImage('assets/noImage.png'),
              ),
            ));
            /* Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Container(
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
                            Text(speakersNames![index],
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ); */
          }),
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
