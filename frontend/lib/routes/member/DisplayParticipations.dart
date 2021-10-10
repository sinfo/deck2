import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/EditBox.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/teamService.dart';

class DisplayParticipations extends StatefulWidget {
  final Member member;
  const DisplayParticipations({Key? key, required this.member})
      : super(key: key);

  @override
  _DisplayParticipationsState createState() => _DisplayParticipationsState();
}

class _DisplayParticipationsState extends State<DisplayParticipations> {
  TeamService teamService = new TeamService();
  late Future<List<Team>> teams;
  List<String> participations = new List<String>.empty(growable: true);

  @override
  void initState() {
    super.initState();
    this.teams = teamService.getTeams(member: widget.member.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: FutureBuilder(
          future: teams,
          builder: (context, snapshot) {  
            print(snapshot.hasData);
            if (snapshot.hasData) {
              List<Team> teams = snapshot.data as List<Team>;

              return ListView(
                children: teams
                    .map((e) =>
                        EditBox(title: e.name!, body: 'Role', edit: false))
                    .toList(),
              );
            } else {
              return Container(
                child: Center(
                  child: Container(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
          }),

        floatingActionButton: FloatingActionButton.extended(
            onPressed: () {},
            label: const Text('Add Participation'),
            icon: const Icon(Icons.add),
            backgroundColor: Color(0xff5C7FF2),
          ),
          
      );

      
}
