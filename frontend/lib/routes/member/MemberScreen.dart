import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/memberPartCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/member/DisplayContact2.dart';
import 'package:frontend/routes/member/EditMemberForm.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/memberService.dart';
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
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

  const MemberBanner({Key? key, required this.member}) : super(key: key);

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
  const DisplayParticipations({Key? key, required this.member, required this.small})
      : super(key: key);

  @override
  _DisplayParticipationsState createState() => _DisplayParticipationsState();
}

class _DisplayParticipationsState extends State<DisplayParticipations> {
  MemberService memberService = new MemberService();
  late Future<List<MemberParticipation>> memberParticipations;
  List<MemberParticipation> participations = [];

  @override
  void initState() {
    super.initState();
    this.memberParticipations = memberService.getMemberParticipations(widget.member.id);
  }

  @override
  Widget build(BuildContext conext) => Scaffold(
        body: FutureBuilder(
            future: memberParticipations,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<MemberParticipation> memParticipations = snapshot.data as List<MemberParticipation>;

                return Scaffold(
                  backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
                  body: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    physics: BouncingScrollPhysics(),
                    children: memParticipations.reversed
                        .map((e) => MemberPartCard(event: e.event!, role: e.role!, team: e.team!, small: widget.small))
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
