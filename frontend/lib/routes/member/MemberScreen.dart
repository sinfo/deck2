import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/routes/member/MemberBanner.dart';
import 'package:frontend/routes/member/DisplayContacts.dart';
import 'package:frontend/routes/member/DisplayParticipations.dart';

class MemberScreen extends StatefulWidget {
  final Member member;
  final String role;
  MemberScreen({Key? key, required this.member, required this.role})
      : super(key: key);

  @override
  _MemberScreen createState() => _MemberScreen(member: member, role: role);
}

class _MemberScreen extends State<MemberScreen> {
  MemberService memberService = new MemberService();
  final Member member;
  final String role;

  _MemberScreen({Key? key, required this.member, required this.role});

  @override
  void initState() {
    super.initState();
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
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MemberBanner(member: this.member, role: this.role),
              DefaultTabController(
                  length: 2, // length of tabs
                  initialIndex: 0,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 310,
                          child: TabBar(
                            labelColor: Colors.black,
                            labelStyle: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                            unselectedLabelStyle: TextStyle(
                                fontWeight: FontWeight.normal, fontSize: 18),
                            indicatorColor: Theme.of(context).accentColor,
                            tabs: [
                              Tab(
                                text: 'Contacts',
                              ),
                              Tab(text: 'Participations'),
                            ],
                          ),
                        ),
                        Container(
                          //FIXME: este número está mal
                            height: 500,
                            child: TabBarView(children: <Widget>[
                              Container(
                                child: DisplayContacts(member: member),
                              ),
                              Container(
                                child: DisplayParticipations(member: member),
                              ),
                            ]))
                      ])),
            ]),
      ),
    );
  }


  
}
