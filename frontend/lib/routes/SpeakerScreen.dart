import 'package:flutter/material.dart';
import 'package:frontend/models/member.dart';

final Map<String,dynamic> speaker = {
	"name" : "John Resig",
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

class SpeakerBanner extends StatelessWidget {
  const SpeakerBanner({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(gradient: SweepGradient(
          center: AlignmentDirectional(-0.3,1.2),
          colors: [Colors.indigo, Colors.indigo.shade200],
          transform: GradientRotation(0)
        ),),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipOval(
                child: Container(
                  child: Image.network(speaker["imgs"]["speaker"]),
                ),
              ),
              SizedBox(width:20), //Padding
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.loose(Size.fromWidth(150)),
                      child: Wrap(
                        runAlignment: WrapAlignment.start,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(speaker['name'], style: Theme.of(context).textTheme.headline5, overflow: TextOverflow.ellipsis,),
                              Text(speaker['title'], style: Theme.of(context).textTheme.subtitle1, softWrap: false, overflow: TextOverflow.ellipsis )
                            ], 
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(color: Colors.amber[100], child: Text('Suggested'),),
                              ElevatedButton(onPressed: () => print('zona'), child: Text('+ Subscribe'))
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}