import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/memberPartCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/member/DisplayContact2.dart';
import 'package:frontend/routes/member/EditMemberForm.dart';
import 'package:frontend/routes/member/MemberNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/teamService.dart';
import 'package:provider/provider.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/models/team.dart';

class MemberScreen extends StatefulWidget {
  late final Member member;

  MemberScreen({Key? key, required this.member}) : super(key: key);

  @override
  _MemberScreen createState() => _MemberScreen();
}

class _MemberScreen extends State<MemberScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  Future<void> memberChangedCallback(BuildContext context,
      {Future<Member?>? fm, Member? member}) async {
    Member? m;
    if (fm != null) {
      m = await fm;
    } else if (member != null) {
      m = member;
    }
    if (m != null) {
      context.read<MemberTableNotifier>().edit(m);
      setState(() {
        widget.member = m!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Scaffold(
        appBar: CustomAppBar(disableEventChange: true),
        body: DefaultTabController(
            length: 2,
            child: Column(children: <Widget>[
              MemberBanner(
                  member: widget.member,
                  onEdit: (context, _member) {
                    memberChangedCallback(context, member: _member);
                  }),
              TabBar(
                isScrollable: small,
                controller: _tabController,
                //FIXME: penso que as label Colors deviam ficam a preto
                tabs: [
                  Tab(text: 'Contacts'),
                  Tab(text: 'Participations'),
                ],
              ),
              Expanded(
                  child: TabBarView(
                controller: _tabController,
                children: [
                  DisplayContacts(member: widget.member),
                  DisplayParticipations(member: widget.member, small: small),
                ],
              ))
            ])),
      );
    });
  }
}

class MemberBanner extends StatefulWidget {
  final Member member;
  final void Function(BuildContext, Member?) onEdit;

  const MemberBanner({Key? key, required this.member, required this.onEdit})
      : super(key: key);

  void _editMemberModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: EditMemberForm(member: member, onEdit: this.onEdit),
        );
      },
    );
  }

  @override
  _MemberBannerState createState() => _MemberBannerState();
}

class _MemberBannerState extends State<MemberBanner> {
  editMember() {
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;
            Member me = Provider.of<Member?>(context)!;

            if (r == Role.ADMIN ||
                r == Role.COORDINATOR ||
                me.id == widget.member.id) {
              return Positioned(
                  bottom: 15,
                  right: 15,
                  child: GestureDetector(
                    onTap: () {
                      widget._editMemberModal(context);
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
                  ));
            } else
              return Container(width: 0);
          } else
            return Container(width: 0);
        });
  }

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    return LayoutBuilder(builder: (context, constraints) {
      //FIXME: colcocar o código dinàmico em relação ao tamanho do dispositivo
      bool small = constraints.maxWidth < App.SIZE;
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
            Stack(children: [
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                padding: const EdgeInsets.all(5),
                child: Hero(
                  tag: widget.member.id + event.toString(),
                  child: ClipOval(
                    child: (widget.member.image == '')
                        ? Image.asset("assets/noImage.png")
                        : Image.network(widget.member.image!),
                  ),
                ),
              ),
              editMember(),
            ]),
            SizedBox(height: 20),
            Text(widget.member.name,
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
  final bool small;
  const DisplayParticipations(
      {Key? key, required this.member, required this.small})
      : super(key: key);

  @override
  _DisplayParticipationsState createState() => _DisplayParticipationsState();
}

class _DisplayParticipationsState extends State<DisplayParticipations> {
  MemberService memberService = new MemberService();
  TeamService teamService = new TeamService();
  AuthService authService = new AuthService();
  late Future<List<MemberParticipation>> memberParticipations;
  List<MemberParticipation> participations = [];

  @override
  void initState() {
    super.initState();
    this.memberParticipations =
        memberService.getMemberParticipations(widget.member.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder(
            future: Future.wait(
                [memberParticipations, Provider.of<AuthService>(context).role]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.hasData) {
                List<MemberParticipation> memParticipations =
                    snapshot.data![0] as List<MemberParticipation>;
                Role r = snapshot.data![1] as Role;
                Member me = Provider.of<Member?>(context)!;
                return Scaffold(
                  backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
                  body: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    children: <Widget>[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        itemCount: memParticipations.length,
                        itemBuilder: (BuildContext context, int index) {
                          var e = memParticipations.reversed.elementAt(index);
                          return MemberPartCard(
                              event: e.event!,
                              cardRole: e.role!,
                              myRole: r.name,
                              team: e.team!,
                              small: widget.small,
                              canEdit: (authService.convert(e.role!) ==
                                      Role.ADMIN)
                                  ? (r == Role.ADMIN)
                                  : (r == Role.ADMIN || r == Role.COORDINATOR),
                              onChanged: (role) async {
                                List<Team> teamsByName =
                                    await teamService.getTeams(name: e.team);
                                Team? team =
                                    await teamService.updateTeamMemberRole(
                                        teamsByName[0].id!,
                                        widget.member.id,
                                        role);
                                if (team == null)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Unable to change that role',
                                            style: TextStyle(
                                                color: Colors.white,
                                                backgroundColor: Colors.red))),
                                  );
                                else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                      'Updated member role',
                                      style: TextStyle(color: Colors.white),
                                    )),
                                  );
                                  if (me.id == widget.member.id) {
                                    await authService.signOut();
                                    Navigator.pushReplacementNamed(
                                        context, Routes.LoginRoute);
                                  }
                                }
                              });
                        },
                      ),
                    ],
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
