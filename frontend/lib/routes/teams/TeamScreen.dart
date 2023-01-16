import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/routes/meeting/MeetingCard.dart';
import 'package:frontend/routes/member/MemberScreen.dart';
import 'package:frontend/routes/teams/AddTeamMemberForm.dart';
import 'package:frontend/routes/teams/TeamsNotifier.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/teamService.dart';
import 'package:frontend/services/authService.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';

import '../../components/blurryDialog.dart';

final Map<String, String> roles = {
  "MEMBER": "Member",
  "TEAMLEADER": "Team Leader",
  "COORDINATOR": "Coordinator",
  "ADMIN": "Administrator"
};

bool membersPage = true;

class TeamScreen extends StatefulWidget {
  Team team;

  TeamScreen({Key? key, required this.team}) : super(key: key);

  @override
  _TeamScreen createState() => _TeamScreen();
}

class _TeamScreen extends State<TeamScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TeamService _teamService = new TeamService();
  MemberService _memberService = new MemberService();
  CustomAppBar appBar = CustomAppBar(disableEventChange: true);
  late List<Future<Member?>> _members;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabIndex);
    _getTeamMembers(widget.team);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabIndex() {
    setState(() {});
  }

  void _getTeamMembers(Team t) {
    _members = t.members!
        .map((teamMember) => _memberService.getMember(teamMember.memberID!))
        .toList();
  }

  Future<void> teamChangedCallback(BuildContext context,
      {Future<Team?>? fm, Team? team}) async {
    Team? m;
    if (fm != null) {
      m = await fm;
    } else if (team != null) {
      m = team;
    }
    if (m != null) {
      Provider.of<TeamsNotifier>(context, listen: false).edit(m);
      setState(() {
        widget.team = m!;
        _getTeamMembers(m);
      });
    }
  }

  void _addTeamMember(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Container(
            child: AddTeamMemberForm(
                team: widget.team,
                onEditTeam: (context, _team) {
                  teamChangedCallback(context, team: _team);
                }),
          ),
        );
      },
    );
  }

  buildSpeedDial(BuildContext context) {
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;

            if (r == Role.ADMIN || r == Role.COORDINATOR) {
              if (membersPage) {
                return SpeedDial(
                  animatedIcon: AnimatedIcons.menu_close,
                  animatedIconTheme: IconThemeData(size: 28.0),
                  backgroundColor: Color(0xff5C7FF2),
                  visible: true,
                  curve: Curves.bounceInOut,
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.person_remove, color: Colors.white),
                      backgroundColor: Colors.indigo,
                      onTap: () => showRemoveMemberDialog(context),
                      label: 'Remove Members',
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                      labelBackgroundColor: Colors.black,
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.person_add, color: Colors.white),
                      backgroundColor: Colors.indigo,
                      onTap: () => _addTeamMember(context),
                      label: 'Add Member',
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                      labelBackgroundColor: Colors.black,
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.delete, color: Colors.white),
                      backgroundColor: Colors.indigo,
                      onTap: () =>
                          showDeleteTeamDialog(context, widget.team.id),
                      label: 'Delete Team',
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                      labelBackgroundColor: Colors.black,
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.edit, color: Colors.white),
                      backgroundColor: Colors.indigo,
                      onTap: () => showEditTeamDialog(),
                      label: 'Edit Team',
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                      labelBackgroundColor: Colors.black,
                    ),
                  ],
                );
              } else {
                return SpeedDial(
                  animatedIcon: AnimatedIcons.menu_close,
                  animatedIconTheme: IconThemeData(size: 28.0),
                  backgroundColor: Color(0xff5C7FF2),
                  visible: true,
                  curve: Curves.bounceInOut,
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.groups, color: Colors.white),
                      backgroundColor: Colors.indigo,
                      onTap: () => {},
                      label: 'Add Meetings',
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                      labelBackgroundColor: Colors.black,
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.delete, color: Colors.white),
                      backgroundColor: Colors.indigo,
                      onTap: () =>
                          showDeleteTeamDialog(context, widget.team.id),
                      label: 'Delete Team',
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                      labelBackgroundColor: Colors.black,
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.edit, color: Colors.white),
                      backgroundColor: Colors.indigo,
                      onTap: () => showEditTeamDialog(),
                      label: 'Edit Team',
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                      labelBackgroundColor: Colors.black,
                    ),
                  ],
                );
              }
            } else {
              return Container(); //CONFIRMAR
            }
          } else {
            return Container();
          }
        });
  }

  showEditTeamDialog() {
    String name = widget.team.name ?? "";
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Edit Team"),
        content: TextFormField(
          initialValue: name,
          onChanged: (value) {
            name = value;
          },
          decoration: const InputDecoration(hintText: "New name for the team"),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, "Cancel"),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => editTeam(widget.team.id, name),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  showDeleteTeamDialog(context, id) {
    final String name = widget.team.name ?? "team";
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return BlurryDialog(
              'Warning', 'Are you sure you want to delete meeting $name?', () {
            deleteTeam(context, id);
          });
        }
        /* =>
          AlertDialog(
        title: const Text("Remove Team"),
        content: Text("Are you sure you want to delete \"$name\"?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, "No"),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => deleteTeam(context, widget.team.id),
            child: const Text("Yes"),
          ),
        ],
      ),*/
        );
  }

  showRemoveMemberDialog(context) async {
    String memberId = "";
    List<Member?> _membs = await Future.wait(_members);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Remove Team Member"),
        content: DropdownButtonFormField(
            validator: (value) {
              if (value == null) {
                return 'Please select one member';
              }
              return null;
            },
            decoration: const InputDecoration(
              icon: const Icon(Icons.grid_3x3),
              labelText: "MemberId *",
            ),
            items: _membs.map((Member? member) {
              return new DropdownMenuItem(
                  value: member!.id, child: Text(member.name));
            }).toList(),
            onChanged: (newValue) {
              setState(() => memberId = newValue.toString());
            }),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, "Cancel"),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                removeTeamMember(context, widget.team.id, memberId),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  showError() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error has occured. Please contact the admins'),
        duration: Duration(seconds: 4),
      ),
    );
    return Center(
        child: Icon(
      Icons.error,
      size: 200,
    ));
  }

  void removeTeamMember(context, String? id, String memberId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog(
            'Warning', 'Are you sure you want to delete this member?',
            () async {
          Team? team = await _teamService.deleteTeamMember(id!, memberId);
          if (team != null) {
            TeamsNotifier notifier =
                Provider.of<TeamsNotifier>(context, listen: false);
            notifier.edit(team);

            teamChangedCallback(context, team: team);

            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Done'),
                duration: Duration(seconds: 2),
              ),
            );

            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An error occured.')),
            );
          }
        });
      },
    );
  }

  void editTeam(String? id, String name) async {
    Team? t = await _teamService.updateTeam(id!, name);
    if (t != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Done'),
          duration: Duration(seconds: 2),
        ),
      );

      teamChangedCallback(context, team: t);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured.')),
      );

      Navigator.pop(context);
    }
    Navigator.pop(context, "Update");
  }

  void deleteTeam(context, String? id) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting')),
    );
    Team? team = await _teamService.deleteTeam(id!);
    if (team != null) {
      TeamsNotifier notifier =
          Provider.of<TeamsNotifier>(context, listen: false);
      notifier.remove(team);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Done'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsNotifier>(builder: (context, notif, child) {
      return Scaffold(
        body: Stack(children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: Container(
              child: DefaultTabController(
                  length: 2,
                  child: Column(children: <Widget>[
                    TeamBanner(team: widget.team),
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      tabs: [
                        Tab(
                          text: 'Members',
                        ),
                        Tab(text: 'Meetings'),
                      ],
                    ),
                    Expanded(
                        child: TabBarView(
                      controller: _tabController,
                      children: [
                        DisplayMembers(members: _members),
                        DisplayMeeting(meetingsIds: widget.team.meetings),
                      ],
                    ))
                  ])),
            ),
          ),
          appBar,
        ]),
        // TODO should only appear in Members tab?
        floatingActionButton: buildSpeedDial(context),
      );
    });
  }
}

class SearchResultWidget extends StatelessWidget {
  final Member? member;
  const SearchResultWidget({Key? key, this.member});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return UnknownScreen();
          }));
        },
        child: Center(
          child: ListTile(
            leading: CircleAvatar(
              foregroundImage: NetworkImage(getImageURL()),
              backgroundImage: AssetImage(
                'assets/noImage.png',
              ),
            ),
            title: Text(getName()),
          ),
        ));
  }

  String getImageURL() {
    if (this.member != null) {
      return this.member!.image!;
    } else {
      //ERROR case
      return "";
    }
  }

  String getName() {
    if (this.member != null) {
      return this.member!.name;
    } else {
      //ERROR case
      return "";
    }
  }
}

class DisplayMeeting extends StatefulWidget {
  final List<String>? meetingsIds;

  DisplayMeeting({Key? key, required this.meetingsIds}) : super(key: key);

  @override
  _DisplayMeetingState createState() => _DisplayMeetingState();
}

class _DisplayMeetingState extends State<DisplayMeeting>
    with AutomaticKeepAliveClientMixin {
  MeetingService _meetingService = new MeetingService();

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<Future<Meeting?>> _futureMeetings =
        widget.meetingsIds!.map((m) => _meetingService.getMeeting(m)).toList();

    membersPage = false;

    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: (widget.meetingsIds == null)
          ? Container()
          : FutureBuilder(
              future: Future.wait(_futureMeetings),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Meeting?> meetings = snapshot.data as List<Meeting?>;

                  return ListView(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      children: meetings
                          .map((e) => MeetingCard(meeting: e!))
                          .toList());
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
    );
  }
}

class DisplayMembers extends StatelessWidget {
  final List<Future<Member?>> members;
  const DisplayMembers({Key? key, required this.members}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
        body: FutureBuilder<List<Member?>>(
            future: Future.wait(members),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<Member?> membs = snapshot.data as List<Member?>;

                return ListView(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    children:
                        membs.map((e) => ShowMember(member: e!)).toList());
              } else {
                return CircularProgressIndicator();
              }
            }));
  }
}

class ShowMember extends StatelessWidget {
  final Member member;
  const ShowMember({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MemberScreen(member: member)));
      },
      child: Card(
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.3),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        margin: EdgeInsets.only(top: 15),
        child: Container(
          height: 100.0,
          child: Row(
            children: <Widget>[
              Container(
                height: 100.0,
                width: 100.0,
                child: (member.image == '')
                    ? Image.asset("assets/noImage.png")
                    : Image.network(member.image!),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5.0),
                      topLeft: Radius.circular(5.0)),
                  image: DecorationImage(
                    image: AssetImage("assets/banner_background.png"),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  member.name,
                  style: TextStyle(color: Colors.black, fontSize: 23.0),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamBanner extends StatelessWidget {
  final Team team;
  const TeamBanner({Key? key, required this.team}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: constraints.maxWidth,
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
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
              padding: const EdgeInsets.all(5),
              child: ClipOval(
                child: Image.asset("assets/DevTeam.jpg", fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 30),
            Text(team.name!,
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}
