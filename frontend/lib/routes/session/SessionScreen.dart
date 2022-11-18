import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/memberPartCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/member/DisplayContact2.dart';
import 'package:frontend/routes/member/EditMemberForm.dart';
import 'package:frontend/routes/session/DisplayGeneralInformation.dart';
import 'package:frontend/routes/session/EditSessionForm.dart';
import 'package:frontend/routes/session/SessionInformationBox.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:provider/provider.dart';

class SessionScreen extends StatefulWidget {
  Session session;

  SessionScreen({Key? key, required this.session}) : super(key: key);

  @override
  _SessionScreen createState() => _SessionScreen();
}

class _SessionScreen extends State<SessionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  _SessionScreen({Key? key});

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
              SessionBanner(session: widget.session),
              TabBar(
                isScrollable: small,
                controller: _tabController,
                //FIXME: penso que as label Colors deviam ficam a preto
                tabs: [
                  Tab(text: 'General Information'),
                  (widget.session.kind == 'TALK')
                      ? Tab(text: 'Speakers')
                      : Tab(text: 'Company'),
                  Tab(text: 'Tickets'),
                ],
              ),
              Expanded(
                  child: TabBarView(
                controller: _tabController,
                children: [
                  DisplayGeneralInformation(
                    session: widget.session,
                  ),
                  // DisplaySpeakers(),
                  DisplayTickets(session: widget.session, small: small),
                ],
              ))
            ])),
      );
    });
  }
}

class SessionBanner extends StatefulWidget {
  final Session session;

  const SessionBanner({Key? key, required this.session}) : super(key: key);

  @override
  _SessionBannerState createState() => _SessionBannerState();
}

class _SessionBannerState extends State<SessionBanner> {
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
                                EditSessionForm(session: widget.session)),
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
            // Stack(children: [
            //   Container(
            //     width: 210,
            //     height: 210,
            //     decoration: BoxDecoration(
            //       shape: BoxShape.circle,
            //       border: Border.all(color: Colors.white30),
            //     ),
            //     padding: const EdgeInsets.all(5),
            //     // child: Hero(
            //     //   tag: widget.member.id + event.toString(),
            //     //   child: ClipOval(
            //     //     child: (widget.member.image == '')
            //     //         ? Image.asset("assets/noImage.png")
            //     //         : Image.network(widget.member.image!),
            //     //   ),
            //     // ),
            //   ),
            //   // editMember(),
            // ]),
            SizedBox(height: 20),
            Text(widget.session.title,
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

class DisplayTickets extends StatefulWidget {
  final Session session;
  final bool small;
  const DisplayTickets({Key? key, required this.session, required this.small})
      : super(key: key);

  @override
  _DisplayTicketsState createState() => _DisplayTicketsState();
}

class _DisplayTicketsState extends State<DisplayTickets> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext conext) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          SessionInformationBox(session: widget.session, type: "description"),
          // InformationBox(title: "Phones", contact: cont, type: "phone"),
          // InformationBox(
          //     title: "Socials",
          //     contact: cont,
          //     type: "social"), //SizedBox(height: 24,),
        ],
      ),
      // floatingActionButton: _isEditable(cont),
    );
  }
}
