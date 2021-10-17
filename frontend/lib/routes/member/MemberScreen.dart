import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/EditBox.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/routes/member/AddMemberForm.dart';
import 'package:frontend/routes/member/DisplayContact2.dart';
import 'package:frontend/routes/member/EditMemberForm.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/teamService.dart';
import '../../main.dart';

class MemberScreen extends StatefulWidget {
  final Member member;
  final String role;
  MemberScreen({Key? key, required this.member, required this.role})
      : super(key: key);

  @override
  _MemberScreen createState() => _MemberScreen(member: member, role: role);
}

class _MemberScreen extends State<MemberScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  MemberService memberService = new MemberService();
  final Member member;
  final String role;

  _MemberScreen({Key? key, required this.member, required this.role});

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
      body: DefaultTabController(
          length: 2,
          child: Column(children: <Widget>[
            MemberBanner(member: widget.member),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              tabs: [
                Tab(
                  text: 'Contacts',
                ),
                Tab(text: 'Participations'),
              ],
            ),
            Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    DisplayContacts(member: widget.member),
                    DisplayParticipations(member: widget.member),
                  ],
                )
            )
          ])),
    );
  }
}

class MemberBanner extends StatelessWidget {
  final Member member;

  const MemberBanner({Key? key, required this.member}) : super(key: key);

  void _editSpeakerModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          //FIXME: edit member form
          child: Container(),
        );
      },
    );
  }

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
            Stack(
              children: [
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: ClipOval(
                    child: (member.image == '')
                        ? Image.asset("assets/noImage.png")
                        : Image.network(member.image!),
                  ),
                ),
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: GestureDetector(
                    //FIXME: on Tap
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditMemberForm(member: member)),
                      );
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        color: Colors.indigo[200],
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                    ),
                  )),
              ]
            ),
            SizedBox(height: 20),
            Text(member.name,
                style: TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}


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
  Widget build(BuildContext conext) => Scaffold(
      body: FutureBuilder(
          future: teams,
          builder: (context, snapshot) {  
            if (snapshot.hasData) {
              List<Team> teams = snapshot.data as List<Team>;

              return Scaffold(
                backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
                body: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  physics: BouncingScrollPhysics(),
                  children: teams
                      .map((e) =>
                          EditBox(title: e.name!, body: 'Em construção', edit: false))
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
          }),
          
      );

      
}

