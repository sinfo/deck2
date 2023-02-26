import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/routes/members_teams/member/MemberListWidget.dart';
import 'package:frontend/routes/members_teams/teams/TeamsNotifier.dart';
import 'package:frontend/routes/members_teams/teams/TeamsTable.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/teamService.dart';
import 'package:provider/provider.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({Key? key}) : super(key: key);

  @override
  _MemberPageState createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TeamService _teamService = TeamService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  bool get wantKeepAlive => true;

  showCreateTeamDialog() {
    String name = "";
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Create New Team"),
        content: TextField(
          onChanged: (value) {
            name = value;
          },
          decoration: const InputDecoration(
              hintText: "Insert the name of the new team"),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, "Cancel"),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => createTeam(name),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void createTeam(String name) async {
    Team? t = await _teamService.createTeam(name);
    if (t != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Done', style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
        ),
      );

      TeamsNotifier notifier =
          Provider.of<TeamsNotifier>(context, listen: false);
      notifier.add(t);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occured.',
                style: TextStyle(color: Colors.white))),
      );

      Navigator.pop(context);
    }
    Navigator.pop(context, "Create");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    CustomAppBar _appBar = CustomAppBar(disableEventChange: true);
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, _appBar.preferredSize.height, 0, 0),
            child: LayoutBuilder(builder: (context, constraints) {
              bool small = constraints.maxWidth < App.SIZE;
              return Column(
                children: [
                  TabBar(
                    isScrollable: small,
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Members by team'),
                      Tab(text: 'All members'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                        controller: _tabController,
                        children: [TeamTable(), MemberListWidget()]),
                  ),
                ],
              );
            })),
        _appBar,
      ]),
      floatingActionButton: FutureBuilder(
          future: Provider.of<AuthService>(context).role,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Role r = snapshot.data as Role;

              if (r == Role.ADMIN || r == Role.COORDINATOR) {
                // return FloatingActionButton.extended(
                //     onPressed: () {
                //       Navigator.pushNamed(
                //         context,
                //         Routes.AddMember,
                //       );
                //     },
                //     label: const Text('Create New Member'),
                //     icon: const Icon(Icons.edit));
                return SpeedDial(
                  icon: Icons.add,
                  activeIcon: Icons.close,
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.people),
                      onTap: showCreateTeamDialog,
                      label: 'Create New Team',
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.person),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.AddMember,
                        );
                      },
                      label: 'Create New Member',
                    ),
                  ],
                );
              } else {
                return Container();
              }
            } else {
              return Container();
            }
          }),
    );
  }
}
