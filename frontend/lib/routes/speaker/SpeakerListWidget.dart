import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/speakerService.dart';

final Map<String, Color> partColor = {
  //For suggested, I can also use Color(0xffEDA460)
  'SUGGESTED': Colors.amber,
  'SELECTED': Colors.deepPurple,
  'ON_HOLD': Colors.blueGrey,
  'CONTACTED': Colors.yellow,
  'IN_CONVERSATIONS': Colors.lightBlue,
  'ACCEPTED': Colors.lightGreen,
  'REJECTED': Colors.red,
  'GIVEN_UP': Colors.black,
  'ANNOUNCED': Colors.green.shade700
};

final double CARD_WIDTH = 200;

class SpeakerListWidget extends StatefulWidget {
  const SpeakerListWidget({Key? key}) : super(key: key);

  @override
  _SpeakerListWidgetState createState() => _SpeakerListWidgetState();
}

class _SpeakerListWidgetState extends State<SpeakerListWidget> {
  SpeakerService speakerService = new SpeakerService();
  late Future<List<Speaker>> speakers;

  @override
  void initState() {
    super.initState();
    this.speakers = speakerService.getSpeakers();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: speakers,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }

        print('Snapshot data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          List<Speaker> comps = snapshot.data as List<Speaker>;

          return Stack(children: <Widget>[
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width ~/ CARD_WIDTH,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.80,
              children: comps
                  .map((e) => SpeakerCard(
                        speaker: e,
                      ))
                  .toList(),
            ),
            Positioned(
                bottom: 15,
                right: 15,
                child: FloatingActionButton(
                  onPressed: () {
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              CreateSpeakerScreen()),
                    );*/
                    debugPrint("Floating Action Button tapped!");
                  },
                  child: const Icon(Icons.add),
                  backgroundColor: Color(0xff5C7FF2),
                ))
          ]);
        } else {
          return CircularProgressIndicator();
        }
      });
}

class SpeakerCard extends StatelessWidget {
  final Speaker speaker;
  const SpeakerCard({Key? key, required this.speaker}) : super(key: key);

  String partName(String participationStatus) {
    int i;
    for (i = 0; i < participationStatus.length; i++) {
      if (participationStatus[i] == '_') {
        break;
      }
    }
    //Assuming that last character is not _
    if (i == participationStatus.length) {
      return participationStatus.substring(0, 1) +
          participationStatus.substring(1).toLowerCase();
    } else {
      return participationStatus.substring(0, 1) +
          participationStatus.substring(1, i).toLowerCase() +
          ' ' +
          participationStatus.substring(i + 1, i + 2) +
          participationStatus.substring(i + 2).toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        /*Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SpeakerScreen(speakerLight: this.speaker)),
        );*/
        debugPrint(this.speaker.name! + " card tapped!");
      },
      child: Column(children: <Widget>[
        Stack(children: <Widget>[
          Image.network(this.speaker.imgs!.internal!, fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
            return progress == null ? child : CircularProgressIndicator();
          }, errorBuilder: (context, exception, stackTrace) {
            return Container(
                width: CARD_WIDTH,
                height: CARD_WIDTH,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xff5C7FF2)),
                child: Center(
                  child: Text(this.speaker.name!.substring(0, 1),
                      style: TextStyle(fontSize: 72, color: Colors.white)),
                ));
          }),
          DecoratedBox(
              decoration: BoxDecoration(
                  color: partColor[this
                      .speaker
                      .participations![this.speaker.participations!.length - 1]
                      .status],
                  borderRadius: BorderRadius.circular(3)),
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: Text(
                    partName(this
                        .speaker
                        .participations![this.speaker.participations!.length - 1]
                        .status
                        .toString()),
                    style: TextStyle(color: Colors.white)),
              ))
        ]),
        DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xffF1F1F1)),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: Text(this.speaker.name!,
                        style: TextStyle(fontWeight: FontWeight.bold))))),
      ]),
    );
  }
}
