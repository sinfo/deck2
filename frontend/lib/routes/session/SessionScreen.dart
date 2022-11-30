import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/routes/session/DisplaySessionInfoScreens/DisplayCompany.dart';
import 'package:frontend/routes/session/DisplaySessionInfoScreens/DisplaySpeakers.dart';
import 'package:frontend/routes/session/DisplaySessionInfoScreens/DisplayGeneralInformation.dart';
import 'package:frontend/routes/session/DisplaySessionInfoScreens/DisplayTickets.dart';
import 'package:frontend/routes/session/SessionBanner.dart';
import 'package:frontend/services/speakerService.dart';

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

    for (var speaker in allSpeakers) {
      for (var id in widget.session.speakersIds!) {
        if (speaker.id == id && (!speakersNames.contains(speaker.name))) {
          setState(() {
            speakersNames.add(speaker.name);
            speakersImages.add(speaker.imgs);
            speakersTitle.add(speaker.title ?? "");
            speakers.add(speaker);
          });
        }
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
