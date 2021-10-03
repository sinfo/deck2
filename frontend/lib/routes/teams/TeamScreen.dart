import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/teamService.dart';

class TeamScreen extends StatefulWidget {
  final Team team;
  TeamScreen({Key? key, required this.team})
      : super(key: key);

  @override
  _TeamScreen createState() => _TeamScreen();
}

class _TeamScreen extends State<TeamScreen> {
  TeamService teamService = new TeamService();

  _TeamScreen({Key? key});

  @override
  void initState() {
    super.initState();
  }

  Widget teamBanner(){
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/banner_background.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(height: 30),
          Text(widget.team.name!,
              style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            child: Image.asset(
          'assets/logo-branco2.png',
          height: 100,
          width: 100,
        )),
      ),
      body: Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              teamBanner(),
              DefaultTabController(
                  length: 2, // length of tabs
                  initialIndex: 0,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 310,
                          child: TabBar(
                            labelColor: Colors.black,
                            labelStyle: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                            unselectedLabelStyle: TextStyle(
                                fontWeight: FontWeight.normal, fontSize: 18),
                            indicatorColor: Theme.of(context).accentColor,
                            tabs: [
                              Tab(
                                text: 'Members',
                              ),
                              Tab(text: 'Meetings'),
                            ],
                          ),
                        ),
                        Container(
                          //FIXME: este número está mal
                            height: 500,
                            child: TabBarView(children: <Widget>[
                              Container(
                                child: Text("Members")
                              ),
                              Container(
                                child: Text('Meetings'),
                              ),
                            ]))
                      ])),
            ]),
      ),
    );
  }


  
}
