import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/routes/member/EditBox.dart';
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
  String participations = "";

  @override
  void initState() {
    super.initState();
    this.teams = teamService.getTeams();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: teams,
      builder: (context, snapshot) {
        print("hello2");
        print(snapshot.hasData);
        //FIXME: eu coloquei aqui prints para tentar fazer debug e percebi que o código
        // não entra no if, idk why
        if (snapshot.hasData) {
          print("hello");
          List<Team> team = snapshot.data as List<Team>;

          print(team.length);
          for (int i = 0; i < team.length; i++) {
            print(43);
            for (int j = 0; j < team[i].members!.length; j++) {
              print(34);
              if (team[i].members![j].memberID == widget.member.id) {
                participations += team[i].name!;
                print(participations);
              }
            }
          }

          return Column(
            children: [
              //FIXME: alterar isto
              EditBox(title: "SINFO $participations", body: ""),
            ],
          );
        } else {
          //FIXME: change
          return CircularProgressIndicator();
        }
      });
}
