import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/teamService.dart';

class TeamTable extends StatefulWidget {
  TeamTable({Key? key}) : super(key: key);

  @override
  _TeamTableState createState() => _TeamTableState();
}

class _TeamTableState extends State<TeamTable> {
  final TeamService _teamService = TeamService();
  late Future<List<Team>> teams;
  late String _filter;

  @override
  void initState() {
    super.initState();
    teams = _teamService.getTeams(event: App.localStorage.getInt("event"));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: teams,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Team> tms = snapshot.data as List<Team>;
            tms.sort((a, b) => a.name!.compareTo(b.name!));
            return ListView(
              children: tms.map((e) => TeamMemberRow(team: e)).toList(),
              addAutomaticKeepAlives: true,
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      );
}

class TeamMemberRow extends StatefulWidget {
  final Team team;
  TeamMemberRow({Key? key, required this.team}) : super(key: key);

  @override
  _TeamMemberRowState createState() => _TeamMemberRowState();
}

class _TeamMemberRowState extends State<TeamMemberRow>
    with AutomaticKeepAliveClientMixin {
  MemberService _memberService = MemberService();
  _TeamMemberRowState();

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildBigTile() {
    List<Future<Member?>> _futureMembers = widget.team.members!
        .map((m) => _memberService.getMember(m.memberID!)).toList();

    return ExpansionTile(
        maintainState: true,
        iconColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: true,
        textColor: Colors.black,
        expandedAlignment: Alignment.topLeft,
        title: Column(
          children: [
            Container(
              child:
                  Text(this.widget.team.name!, style: TextStyle(fontSize: 18)),
              margin: EdgeInsets.all(8),
            ),
            Divider(
              color: Colors.grey,
              thickness: 1,
            ),
          ],
        ),
        children: [
          FutureBuilder(
              future: Future.wait(_futureMembers),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Member> membs = snapshot.data as List<Member>;
                  return Container(
                    height: membs.length == 0 ? 0 : null,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: membs
                          .map((e) => ListViewCard(small: false, member: e))
                          .toList(),
                    ),
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
              })
        ]);
  }

  Widget _buildSmallTile() {
    List<Future<Member?>> _futureMembers = widget.team.members!
        .map((m) => _memberService.getMember(m.memberID!)).toList();

    return ExpansionTile(
      iconColor: Colors.transparent,
      initiallyExpanded: true,
      textColor: Colors.black,
      expandedAlignment: Alignment.topLeft,
      title: Column(
        children: [
          Container(
            child: Text(this.widget.team.name!, style: TextStyle(fontSize: 12)),
            margin: EdgeInsets.all(8),
          ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      ),
      children: [
        FutureBuilder(
          future: Future.wait(_futureMembers),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Member> membs = snapshot.data as List<Member>;
              return Container(
                height: _futureMembers.length == 0 ? 0 : 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:  membs
                      .map((e) => ListViewCard(small: true, member: e))
                      .toList(),
                ),
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
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 1500) {
              return _buildSmallTile();
            } else {
              return _buildBigTile();
            }
          })),
    );
  }
}
