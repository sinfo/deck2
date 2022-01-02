import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/EditBox.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/routes/member/EditContact.dart';
import 'package:frontend/routes/member/EditMemberForm.dart';
import 'package:frontend/routes/member/InformationBox.dart';
import 'package:frontend/routes/member/MemberNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/contactService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/teamService.dart';
import 'package:provider/provider.dart';

class MemberScreen extends StatefulWidget {
  Member member;

  MemberScreen({Key? key, required this.member}) : super(key: key);

  @override
  _MemberScreen createState() => _MemberScreen();
}

class _MemberScreen extends State<MemberScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  _MemberScreen({Key? key});

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

  Future<void> speakerChangedCallback(BuildContext context,
      {Future<Member?>? fm, Member? member}) async {
    Member? m;
    if (fm != null) {
      m = await fm;
    } else if (member != null) {
      m = member;
    }
    if (m != null) {
      Provider.of<MemberTableNotifier>(context, listen: false).edit(m);
      setState(() {
        widget.member = m!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Consumer<MemberTableNotifier>(builder: (context, notif, child) {
        return Scaffold(
          appBar: CustomAppBar(disableEventChange: true),
          body: DefaultTabController(
              length: 2,
              child: Column(children: <Widget>[
                MemberBanner(member: widget.member),
                TabBar(
                  isScrollable: small,
                  controller: _tabController,
                  //FIXME: penso que as label Colors deviam ficam a preto
                  labelColor: Colors.black,
                  tabs: [
                    Tab(text: 'Contacts'),
                    Tab(text: 'Participations'),
                  ],
                ),
                Expanded(
                    child: TabBarView(
                  controller: _tabController,
                  children: [
                    DisplayContacts(
                      member: widget.member,),
                    DisplayParticipations(member: widget.member),
                  ],
                ))
              ])),
        );
      });
    });
  }
}

class MemberBanner extends StatefulWidget {
  final Member member;

  const MemberBanner({Key? key, required this.member}) : super(key: key);

  @override
  _MemberBannerState createState() => _MemberBannerState();
}

class _MemberBannerState extends State<MemberBanner> {
  deleteMember() {
    MemberService _memberService = MemberService();
    TeamService _teamService = TeamService();

    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;

            if (r == Role.ADMIN || r == Role.COORDINATOR) {
              return Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    BlurryDialog d = BlurryDialog('Warning',
                        'Are you sure you want to delete this member?',
                        () async {
                      List<Team?> t =
                          await _teamService.getTeams(member: widget.member.id);

                      //Remove Member
                      await _memberService.deleteMember(widget.member.id);

                      Navigator.pop(context);
                    });

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return d;
                      },
                    );
                  },
                  icon: Icon(Icons.delete),
                  color: Colors.white,
                ),
              );
            } else
              return Container(width: 0);
          } else
            return Container(width: 0);
        });
  }

  editMember() {
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;

            if (r == Role.ADMIN || r == Role.COORDINATOR) {
              return Positioned(
                  bottom: 15,
                  right: 15,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EditMemberForm(member: widget.member)),
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
                  ));
            } else
              return Container(width: 0);
          } else
            return Container(width: 0);
        });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      //FIXME: colcocar o código dinàmico em relação ao tamanho do dispositivo
      //bool small = constraints.maxWidth < App.SIZE;
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
            deleteMember(),
            Stack(children: [
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                padding: const EdgeInsets.all(5),
                child: ClipOval(
                  child: (widget.member.image == '')
                      ? Image.asset("assets/noImage.png")
                      : Image.network(widget.member.image!),
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
            SizedBox(height: 30),
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
                    //TODO: preciso de descobrir o evento em que a team está
                    children: teams.reversed
                        .map((e) => EditBox(
                            //FIXME: buscar a equipa em que o membro esteve numa dada edição
                            title: 'SINFO number',
                            body: e.name!,
                            edit: false))
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

class DisplayContacts extends StatefulWidget {
  final Member member;
  const DisplayContacts({Key? key, required this.member}) : super(key: key);

  @override
  _DisplayContactsState createState() => _DisplayContactsState();
}

class _DisplayContactsState extends State<DisplayContacts> {
  ContactService contactService = new ContactService();
  late Future<Contact?> contact;

  @override
  void initState() {
    super.initState();
    this.contact = contactService.getContact(widget.member.contact!);
  }

  _isEditable(Contact cont) {
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;

            if (r == Role.ADMIN || r == Role.COORDINATOR) {
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EditContact(contact: cont, member: widget.member)),
                  );
                },
                label: const Text('Edit Contacts'),
                icon: const Icon(Icons.edit),
                backgroundColor: Color(0xff5C7FF2),
              );
            } else
              return Container();
          } else
            return Container();
        });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: contact,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Contact cont = snapshot.data as Contact;
          return Scaffold(
            backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
            body: ListView(
              padding: EdgeInsets.symmetric(horizontal: 32),
              physics: BouncingScrollPhysics(),
              children: [
                InformationBox(title: "Mails", contact: cont, type: "mail"),
                InformationBox(title: "Phones", contact: cont, type: "phone"),
                InformationBox(
                    title: "Socials",
                    contact: cont,
                    type: "social"), //SizedBox(height: 24,),
              ],
            ),
            floatingActionButton: _isEditable(cont),
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
      });
}
