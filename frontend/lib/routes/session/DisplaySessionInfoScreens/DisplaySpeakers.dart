import 'package:flutter/material.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/speaker/SpeakerScreen.dart';
import 'package:frontend/services/speakerService.dart';

class DisplaySpeakers extends StatefulWidget {
  final Session session;
  final List<String> speakersNames;
  final List<Images?> speakersImages;
  final List<String?> speakersTitle;
  final List<Speaker> speakers;
  const DisplaySpeakers(
      {Key? key,
      required this.session,
      required this.speakersNames,
      required this.speakersImages,
      required this.speakersTitle,
      required this.speakers})
      : super(key: key);

  @override
  _DisplaySpeakersState createState() => _DisplaySpeakersState();
}

class _DisplaySpeakersState extends State<DisplaySpeakers> {
  SpeakerService speakerService = new SpeakerService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.speakers.length != 0) {
      return Scaffold(
        backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
        body: new ListView.builder(
            itemCount: widget.session.speakersIds!.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 7.0,
                            color: Colors.grey.withOpacity(0.3),
                            offset: new Offset(0, 3),
                            spreadRadius: 4.0),
                      ]),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SpeakerScreen(
                                    speaker: widget.speakers[index],
                                  ))); //TODO
                    },
                    title: Text(widget.speakersNames[index],
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 18)),
                    subtitle: (widget.speakersTitle[index] != "")
                        ? Text(widget.speakersTitle[index]!)
                        : Text("No titles avaible for this speaker."),
                    leading: CircleAvatar(
                      radius: 26.0,
                      foregroundImage: NetworkImage(
                        widget.speakersImages[index]!.speaker ??
                            (widget.speakersImages[index]!.internal ??
                                (widget.speakersImages[index]!.company ?? "")),
                      ),
                      backgroundImage: AssetImage('assets/noImage.png'),
                    ),
                  ));
            }),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Container(
              height: 40,
              width: 40,
              margin: EdgeInsets.all(5),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }
  }
}
