import 'package:flutter/material.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/components/threads/addThreadForm.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/threads/participations/communicationsList.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/components/DisplayContact2.dart';
import 'package:frontend/routes/speaker/DetailsScreen.dart';
import 'package:frontend/routes/speaker/ParticipationList.dart';
import 'package:frontend/routes/speaker/banner/SpeakerBanner.dart';
import 'package:frontend/routes/speaker/flights/AddFlightInfoForm.dart';
import 'package:frontend/routes/speaker/flights/flightInfoScreen.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';

class SpeakerScreen extends StatefulWidget {
  Speaker speaker;

  SpeakerScreen({Key? key, required this.speaker}) : super(key: key);

  @override
  _SpeakerScreenState createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends State<SpeakerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final SpeakerService _speakerService;
  CustomAppBar appBar = CustomAppBar(disableEventChange: true);

  @override
  void initState() {
    super.initState();
    _speakerService = SpeakerService();
    _tabController = TabController(length: 5, vsync: this);
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
      {Future<Speaker?>? fs, Speaker? speaker}) async {
    Speaker? s;
    if (fs != null) {
      s = await fs;
    } else if (speaker != null) {
      s = speaker;
    }
    if (s != null) {
      Provider.of<SpeakerTableNotifier>(context, listen: false).edit(s);
      setState(() {
        widget.speaker = s!;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Done.', style: TextStyle(color: Colors.white))),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occured.',
                style: TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Consumer<SpeakerTableNotifier>(builder: (context, notif, child) {
        return Scaffold(
          body: Stack(children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
              child: Column(
                children: [
                  SpeakerBanner(
                      speaker: widget.speaker,
                      statusChangeCallback: (step, context) {
                        speakerChangedCallback(
                          context,
                          fs: _speakerService.stepParticipationStatus(
                              id: widget.speaker.id, step: step),
                        );
                      },
                      onEdit: (context, _speaker) {
                        speakerChangedCallback(context, speaker: _speaker);
                      },
                      onDelete: () {
                        speakerChangedCallback(context, fs: () async {
                          Speaker? s = await _speakerService.deleteSpeaker(
                              id: widget.speaker.id);
                          if (s != null) {
                            Navigator.popAndPushNamed(
                                context, Routes.HomeRoute);
                          }
                          return s;
                        }());
                      }),
                  TabBar(
                    isScrollable: small,
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Details'),
                      Tab(text: 'Contacts'),
                      Tab(text: 'FlightInfo'),
                      Tab(text: 'Participations'),
                      Tab(text: 'Communications'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(controller: _tabController, children: [
                      DetailsScreen(
                        speaker: widget.speaker,
                      ),
                      DisplayContacts(person: widget.speaker),
                      FlightInfoScreen(
                          participations: widget.speaker.participations ?? [],
                          id: widget.speaker.id,
                          small: small,
                          onFlightDeleted: (flightId) => speakerChangedCallback(
                              context,
                              fs: _speakerService.removeFlightInfo(
                                  flightInfoId: flightId,
                                  id: widget.speaker.id))),
                      widget.speaker.participations!.isEmpty
                          ? Center(child: Text('No participations yet'))
                          : ParticipationList(
                              speaker: widget.speaker,
                              onParticipationChanged:
                                  (Map<String, dynamic> body) async {
                                await speakerChangedCallback(
                                  context,
                                  fs: _speakerService.updateParticipation(
                                    id: widget.speaker.id,
                                    feedback: body['feedback'],
                                    member: body['member'],
                                    room: body['room'],
                                  ),
                                );
                              },
                              onChangePartStatus:
                                  (ParticipationStatus status) async {
                                await speakerChangedCallback(
                                  context,
                                  fs: _speakerService.updateParticipationStatus(
                                      id: widget.speaker.id, newStatus: status),
                                );
                              },
                              onParticipationDeleted: () =>
                                  speakerChangedCallback(context,
                                      fs: _speakerService.removeParticipation(
                                          id: widget.speaker.id)),
                              onParticipationAdded: () =>
                                  speakerChangedCallback(context,
                                      fs: _speakerService.addParticipation(
                                          id: widget.speaker.id)),
                            ),
                      widget.speaker.participations!.isEmpty
                          ? Center(child: Text('No communications yet'))
                          : CommunicationsList(
                              participations:
                                  widget.speaker.participations != null
                                      ? widget.speaker.participations!.reversed
                                          .toList()
                                      : [],
                              small: small,
                              onCommunicationDeleted: (thread_ID) =>
                                  speakerChangedCallback(context,
                                      fs: _speakerService.deleteThread(
                                          id: widget.speaker.id,
                                          threadID: thread_ID)),
                            ),
                    ]),
                  ),
                ],
              ),
            ),
            appBar,
          ]),
          floatingActionButton: _fabAtIndex(context),
        );
      });
    });
  }

  void _addThreadModal(mainContext) {
    showModalBottomSheet(
      context: mainContext,
      builder: (context) {
        return Container(
          child: AddThreadForm(
            speaker: widget.speaker,
            onAddSpeaker: (thread_text, thread_kind) {
              speakerChangedCallback(mainContext,
                  fs: _speakerService.addThread(
                      id: widget.speaker.id,
                      kind: thread_kind,
                      text: thread_text));
            },
          ),
        );
      },
    );
  }

  Widget? _fabAtIndex(BuildContext context) {
    int latestEvent = Provider.of<EventNotifier>(context).latest.id;
    int index = _tabController.index;
    switch (index) {
      case 0:
        return null;
      case 1:
        return null;
      case 2:
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddFlightInfoForm(
                      id: widget.speaker.id,
                      onEditSpeaker: (context, _speaker) {
                        speakerChangedCallback(context, speaker: _speaker);
                      }),
                ));
          },
          label: const Text('Add Flight Information'),
          icon: const Icon(Icons.add),
        );
      case 3:
        {
          bool hasCurrentParticipation =
              !widget.speaker.participations!.isEmpty &&
                  widget
                          .speaker
                          .participations![
                              widget.speaker.participations!.length - 1]
                          .event ==
                      latestEvent;
          return hasCurrentParticipation
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    speakerChangedCallback(context,
                        fs: _speakerService.addParticipation(
                            id: widget.speaker.id));
                  },
                  label: const Text('Add Participation'),
                  icon: const Icon(Icons.add),
                );
        }
      case 4:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              _addThreadModal(context);
            },
            label: const Text('Add Communication'),
            icon: const Icon(Icons.add),
          );
        }
      default:
        return null;
    }
  }
}
