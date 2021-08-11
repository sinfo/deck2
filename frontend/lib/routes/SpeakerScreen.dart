import 'package:flutter/material.dart';
import 'package:frontend/models/member.dart';

enum ParticipationStatus {
  SUGGESTED,
  SELECTED,
  ON_HOLD,
  CONTACTED,
  IN_CONVERSATIONS,
  ACCEPTED,
  REJECTED,
  GIVEN_UP,
  ANNOUNCED
}

final Map<ParticipationStatus,String> STATUSSTRING = {
  ParticipationStatus.ACCEPTED: 'Accepted',
  ParticipationStatus.ANNOUNCED: 'Announced',
  ParticipationStatus.CONTACTED: 'Contacted',
  ParticipationStatus.GIVEN_UP: 'Given Up',
  ParticipationStatus.IN_CONVERSATIONS: 'In Convers.',
  ParticipationStatus.ON_HOLD: 'On Hold',
  ParticipationStatus.REJECTED: 'Rejected',
  ParticipationStatus.SELECTED: 'Selected',
  ParticipationStatus.SUGGESTED: 'Suggested',
};

final Map<ParticipationStatus,Color> STATUSCOLOR = {
  ParticipationStatus.ACCEPTED: Colors.lightGreen,
  ParticipationStatus.ANNOUNCED: Colors.green.shade700,
  ParticipationStatus.CONTACTED: Colors.yellow,
  ParticipationStatus.GIVEN_UP: Colors.black,
  ParticipationStatus.IN_CONVERSATIONS: Colors.lightBlue,
  ParticipationStatus.ON_HOLD: Colors.blueGrey,
  ParticipationStatus.REJECTED: Colors.red,
  ParticipationStatus.SELECTED: Colors.deepPurple,
  ParticipationStatus.SUGGESTED: Colors.amber,
};



final Map<String,dynamic> speaker = {
	"name" : "Reginald Fils-Aime",
	"title" : "Creator of jQuery",
	"participations" : [
		{
			"event" : 22,
			"status" : "REJECTED",
			"subscribers" : [ ],
			"feedback" : "",
			"flights" : [ ],
		},
		{
			"event" : 23,
			"status" : "CONTACTED",
			"communications" : [
			],
			"subscribers" : [ ],
			"feedback" : "",
			"flights" : [ ],
		},
		{
			"event" : 24,
			"status" : "REJECTED",
			"subscribers" : [ ],
			"feedback" : "",
			"flights" : [ ],
		},
		{
			"event" : 25,
			"status" : "REJECTED",
			"subscribers" : [ ],
			"feedback" : "",
			"flights" : [ ],
		}
	],
	"employers" : [ ],
	"imgs" : {
		"internal" : "http://upload.wikimedia.org/wikipedia/commons/c/cd/Jresig.png",
		"speaker" : "http://upload.wikimedia.org/wikipedia/commons/c/cd/Jresig.png",
		"company" : ""
	},
	"bio" : "John Resig is the Dean of Computer Science at Khan Academy and the creator of the jQuery JavaScript library. He’s also the author of the books Pro JavaScript Techniques and Secrets of the JavaScript Ninja.\nJohn is a Visiting Researcher at Ritsumeikan University in Kyoto working on the study of Ukiyo-e (Japanese Woodblock printing). He has developed a comprehensive woodblock print database and image search engine located at: Ukiyo-e.org. Currently, John is located in Brooklyn, NY.",
	"site" : "",
};

class SpeakerScreen extends StatelessWidget {
  const SpeakerScreen({ Key? key }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          SpeakerBanner(),
          TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.indigo[100],
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'FlightInfo'),
              Tab(text: 'Participations'),
              Tab(text: 'Communications'),
            ],
          ),
          Expanded(
            child: TabBarView(children: [
              Container(decoration: BoxDecoration(color: Colors.red)),
              Container(decoration: BoxDecoration(color: Colors.amber)),
              Container(decoration: BoxDecoration(color: Colors.green)),
              Container(decoration: BoxDecoration(color: Colors.teal)),
            ]),
          ),
        ],
      ),
    );
  }
}
class SpeakerBanner extends StatefulWidget {
  const SpeakerBanner({ Key? key }) : super(key: key);

  @override
  _SpeakerBannerState createState() => _SpeakerBannerState();
}

class _SpeakerBannerState extends State<SpeakerBanner> {
  ParticipationStatus? previousStatus;
  ParticipationStatus speakerStatus = ParticipationStatus.values.firstWhere((element) {
    return element.toString() == 'ParticipationStatus.' + 
        speaker['participations'][(speaker['participations'] as List).length-1]["status"];
    }
  );

  void revertSpeakerStatus() {
    setState(() {
      speakerStatus = previousStatus!;
      //call service method to change par
    });
  }

  void changeSpeakerStatus(ParticipationStatus? newStatus, BuildContext context){
    setState(() {
      previousStatus = speakerStatus;
      speakerStatus = newStatus!;
      //call service method to change participations status
      final SnackBar snackBar = SnackBar(
        content: Text('Speaker status updated'),
        action: SnackBarAction(label: 'Undo', onPressed: revertSpeakerStatus),
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(
          colors: [STATUSCOLOR[speakerStatus]!.withAlpha(100  ), Colors.white],
          transform: GradientRotation(0)
        ),),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [ 
              ClipOval(
                child: Container(
                  child: Image.network(speaker["imgs"]["speaker"],),
                ),
              ),
              SizedBox(width:20), //Padding
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(speaker['name'], style: Theme.of(context).textTheme.headline5, overflow: TextOverflow.ellipsis,),
                      Text(speaker['title'], style: Theme.of(context).textTheme.subtitle1, softWrap: false, overflow: TextOverflow.ellipsis ),
                      SpeakerStatusDropdownButton(speakerStatus: speakerStatus, statusChangeCallback: changeSpeakerStatus,),
                      ElevatedButton(onPressed: () => print('zona'), child: Text('+ Subscribe'))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  } 
}
class SpeakerStatusDropdownButton extends StatelessWidget {
  final void Function(ParticipationStatus?, BuildContext) statusChangeCallback;
  final ParticipationStatus speakerStatus;
  const SpeakerStatusDropdownButton({ Key? key, required this.statusChangeCallback, required this.speakerStatus }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: DropdownButton<ParticipationStatus>(
        underline: Container(
          height: 3,
          decoration: BoxDecoration(color: Theme.of(context).accentColor),
        ),
        value: speakerStatus,
        style: Theme.of(context).textTheme.subtitle2,
        selectedItemBuilder: (BuildContext context) {
          return ParticipationStatus.values.map((e) {
            return Align(
              alignment: AlignmentDirectional.centerStart ,
              child: Container(
                child: Text(STATUSSTRING[e]!)
              ),
            );
          }).toList();
        },
        items: ParticipationStatus.values
            .map((e) => DropdownMenuItem<ParticipationStatus>(
              value: e, 
              child: Text(STATUSSTRING[e]!),
            )).toList(),
        onChanged: (status) {
          statusChangeCallback(status, context);
        },
        
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      Column(
        children: [],
      )
    );
  }
}

