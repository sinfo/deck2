import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/memberPartCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
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
import 'package:frontend/services/speakerService.dart';
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
  SpeakerService speakerService = new SpeakerService();
  List<Speaker> allSpeakers = [];
  List<String> speakersNames = [];
  List<Images?> speakersImages = [];
  List<String?> speakersTitle = [];
  List<Speaker> speakers = [];

  _SessionScreen({Key? key});

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabIndex);
    fillSpeakers();
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

  Future<void> fillSpeakers() async {
    Future<List<Speaker>> speakersFuture = speakerService.getSpeakers();

    allSpeakers = await speakersFuture;
    print("ALL SPEAKERS");
    print(allSpeakers);

    for (var speaker in allSpeakers) {
      // print("Here");
      for (var id in widget.session.speakersIds!) {
        // print("There");
        if (speaker.id == id && (!speakersNames.contains(speaker.name))) {
          print("ADDED");
          print(speaker.name);
          setState(() {
            speakersNames.add(speaker.name);
            speakersImages.add(speaker.imgs);
            speakersTitle.add(speaker.title ?? "");
            print("Speaker title: " + speaker.title!);
            speakers.add(speaker);
          });
        } /* else {
          print("Ids are different.");
          print("Id from session: " + id);
          print("Id from speaker: " + speaker.id);
        } */
      }
    }
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
              SessionBanner(session: widget.session /* , key: UniqueKey() */),
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
                          speakersNames: speakersNames,
                          speakersImages: speakersImages,
                          speakersTitle: speakersTitle,
                          speakers: speakers,
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
