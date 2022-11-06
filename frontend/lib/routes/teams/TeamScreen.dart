import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/routes/meeting/MeetingCard.dart';
import 'package:frontend/routes/member/MemberScreen.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:frontend/services/teamService.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class TeamScreen extends StatefulWidget {
  final Team team;
  final List<Member?> members;

  TeamScreen({Key? key, required this.team, required this.members})
      : super(key: key);

  @override
  _TeamScreen createState() => _TeamScreen();
}

class _TeamScreen extends State<TeamScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TeamService _teamService = new TeamService();

  _TeamScreen({Key? key});

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabIndex);
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

  SpeedDial buildSpeedDial() {
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
          // TODO
          onTap: () => print('Remove Members'),
          label: 'Remove Members',
          labelStyle:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.black,
        ),
        SpeedDialChild(
          child: Icon(Icons.person_add, color: Colors.white),
          backgroundColor: Colors.indigo,
          // TODO
          onTap: () => print('Add Members'),
          label: 'Add Members',
          labelStyle:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.black,
        ),
        SpeedDialChild(
          child: Icon(Icons.delete, color: Colors.white),
          backgroundColor: Colors.indigo,
          onTap: () => showDeleteTeamDialog(),
          label: 'Delete Team',
          labelStyle:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.black,
        ),
        SpeedDialChild(
          child: Icon(Icons.edit, color: Colors.white),
          backgroundColor: Colors.indigo,
          onTap: () => showEditTeamDialog(),
          label: 'Edit Team',
          labelStyle:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          labelBackgroundColor: Colors.black,
        ),
      ],
    );
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

  showDeleteTeamDialog() {
    final String name = widget.team.name ?? "team";
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Remove Team"),
        content: Text("Are you sure you want to delete \"$name\"?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, "No"),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => deleteTeam(widget.team.id),
            child: const Text("Yes"),
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

  void editTeam(String? id, String name) async {
    if (id == null) {
      showError();
    } else {
      final response = await _teamService.updateTeam(id, name);
      setState(() {
        widget.team.name = response?.name ?? "Empty name";
      });
    }
    Navigator.pop(context, "Update");
  }

  void deleteTeam(String? id) async {
    if (id == null) {
      showError();
      return;
    } else {
      final response = await _teamService.deleteTeam(id);
      Navigator.pop(context, "Update");
    }
    // TODO when going back to TeamTable, it should be refreshed so that the deleted team is not shown. What is the best option to do this?
    Navigator.pop(context);
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
                  DisplayMembers(members: widget.members),
                  DisplayMeeting(meetingsIds: widget.team.meetings),
                ],
              ))
            ])),
      ),
      // TODO should only appear in Members tab?
      floatingActionButton: buildSpeedDial(),
    );
  }
}

class DisplayMeeting extends StatefulWidget {
  final List<String>? meetingsIds;

  DisplayMeeting({Key? key, required this.meetingsIds}) : super(key: key);

  @override
  _DisplayMeetingState createState() => _DisplayMeetingState();
}

class _DisplayMeetingState extends State<DisplayMeeting> {
  MeetingService _meetingService = new MeetingService();

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    List<Future<Meeting?>> _futureMeetings =
        widget.meetingsIds!.map((m) => _meetingService.getMeeting(m)).toList();

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Add Meetings'),
        icon: const Icon(Icons.edit),
        backgroundColor: Color(0xff5C7FF2),
      ),
    );
  }
}

class DisplayMembers extends StatelessWidget {
  final List<Member?> members;
  const DisplayMembers({Key? key, required this.members}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 32),
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.vertical,
          children: members.map((e) => ShowMember(member: e!)).toList()),
    );
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
                builder: (context) => MemberScreen(member: member))); //TODO
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
