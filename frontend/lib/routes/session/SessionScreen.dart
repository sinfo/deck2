import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/memberPartCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/member/EditMemberForm.dart';
import 'package:frontend/routes/session/DisplayCompany.dart';
import 'package:frontend/routes/session/DisplaySpeakers.dart';
import 'package:frontend/routes/session/DisplayGeneralInformation.dart';
import 'package:frontend/routes/session/DisplayTickets.dart';
import 'package:frontend/routes/session/EditSessionForm.dart';
import 'package:frontend/routes/session/SessionBanner.dart';
import 'package:frontend/routes/session/SessionInformationBox.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/sessionService.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
            length: 3,
            child: Column(children: <Widget>[
              SessionBanner(session: widget.session),
              TabBar(
                isScrollable: small,
                controller: _tabController,
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
                  (widget.session.kind == 'TALK')
                      ? DisplaySpeakers(
                          session: widget.session,
                        )
                      : DisplayCompany(session: widget.session),
                  DisplayTickets(session: widget.session),
                ],
              ))
            ])),
      );
    });
  }
}
