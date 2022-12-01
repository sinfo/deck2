import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/components/threads/addThreadForm.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/components/threads/participations/communicationsList.dart';
import 'package:frontend/components/threads/threadCard/threadCard.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/routes/speaker/flights/AddFlightInfoForm.dart';
import 'package:frontend/routes/speaker/flights/flightInfoScreen.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/speaker/EditSpeakerForm.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

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

  @override
  void initState() {
    super.initState();
    _speakerService = SpeakerService();
    _tabController = TabController(length: 4, vsync: this);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Consumer<SpeakerTableNotifier>(builder: (context, notif, child) {
        return Scaffold(
          appBar: CustomAppBar(disableEventChange: true),
          body: Column(
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
                  }),
              TabBar(
                isScrollable: small,
                controller: _tabController,
                tabs: [
                  Tab(text: 'Details'),
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
                  FlightInfoScreen(
                      participations: widget.speaker.participations ?? [],
                      id: widget.speaker.id,
                      small: small,
                      onFlightDeleted: (flightId) => speakerChangedCallback(
                          context,
                          fs: _speakerService.removeFlightInfo(
                              flightInfoId: flightId, id: widget.speaker.id))),
                  ParticipationList(
                    speaker: widget.speaker,
                    onParticipationChanged: (Map<String, dynamic> body) async {
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
                    onParticipationDeleted: () => speakerChangedCallback(
                        context,
                        fs: _speakerService.removeParticipation(
                            id: widget.speaker.id)),
                  ),
                  CommunicationsList(
                    participations: widget.speaker.participations ?? [],
                    small: small,
                    onCommunicationDeleted: (thread_ID) =>
                        speakerChangedCallback(context,
                            fs: _speakerService.deleteThread(
                                id: widget.speaker.id, threadID: thread_ID)),
                  ),
                ]),
              ),
            ],
          ),
          floatingActionButton: _fabAtIndex(context),
        );
      });
    });
  }

  void _addThreadModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: AddThreadForm(
              speaker: widget.speaker,
              onEditSpeaker: (context, _speaker) {
                speakerChangedCallback(context, speaker: _speaker);
              }),
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
      case 2:
        {
          if (widget.speaker.lastParticipation != latestEvent) {
            return FloatingActionButton.extended(
              onPressed: () => speakerChangedCallback(context,
                  fs: _speakerService.addParticipation(id: widget.speaker.id)),
              label: const Text('Add Participation'),
              icon: const Icon(Icons.add),
            );
          } else {
            return null;
          }
        }
      case 3:
        {
          return FloatingActionButton.extended(
            onPressed: () {
              _addThreadModal(context);
            },
            label: const Text('Add Communication'),
            icon: const Icon(Icons.add),
          );
        }
    }
  }
}

class ParticipationList extends StatelessWidget {
  final Speaker speaker;
  final Future<void> Function(Map<String, dynamic>) onParticipationChanged;
  final void Function() onParticipationDeleted;
  const ParticipationList({
    Key? key,
    required this.speaker,
    required this.onParticipationChanged,
    required this.onParticipationDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        if (speaker.participations != null) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: ListView(
                controller: ScrollController(),
                children: speaker.participations!.reversed
                    .map((e) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ParticipationCard(
                            participation: e,
                            small: small,
                            type: CardType.SPEAKER,
                            onEdit: onParticipationChanged,
                            onDelete: onParticipationDeleted,
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class SpeakerBanner extends StatelessWidget {
  final Speaker speaker;
  final void Function(int, BuildContext) statusChangeCallback;
  final void Function(BuildContext, Speaker?) onEdit;
  const SpeakerBanner(
      {Key? key,
      required this.speaker,
      required this.statusChangeCallback,
      required this.onEdit})
      : super(key: key);

  void _editSpeakerModal(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: EditSpeakerForm(speaker: speaker, onEdit: this.onEdit),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    bool isEditable = Provider.of<EventNotifier>(context).isLatest;
    Participation? part = speaker.participations!
        .firstWhereOrNull((element) => element.event == event);
    ParticipationStatus speakerStatus =
        part != null ? part.status : ParticipationStatus.NO_STATUS;

    double lum = 0.2;
    var matrix = <double>[
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]; // Greyscale matrix. Lum represents level of luminosity
    return LayoutBuilder(
      builder: (context, constraints) {
        bool small = constraints.maxWidth < App.SIZE;
        return Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  colorFilter: Provider.of<ThemeNotifier>(context).isDark
                      ? ColorFilter.matrix(matrix)
                      : null,
                  image: AssetImage('assets/banner_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: small ? 4 : 20, vertical: small ? 5 : 25),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(8.0, 8.0, small ? 8 : 20.0, 8.0),
                      child: SizedBox(
                        height: small ? 100 : 150,
                        width: small ? 100 : 150,
                        child: Hero(
                          tag: speaker.id + event.toString(),
                          child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: small ? 2 : 4,
                                  color: STATUSCOLOR[speakerStatus]!,
                                )),
                            child: CircleAvatar(
                              foregroundImage: NetworkImage(
                                speaker.imgs!.speaker ??
                                    (speaker.imgs!.internal ??
                                        (speaker.imgs!.company ?? "")),
                              ),
                              backgroundImage: AssetImage('assets/noImage.png'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(small ? 8 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              speaker.name,
                              style: Theme.of(context).textTheme.headline5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(speaker.title!,
                                style: Theme.of(context).textTheme.subtitle1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis),
                            if (isEditable)
                              SpeakerStatusDropdownButton(
                                speakerStatus: speakerStatus,
                                statusChangeCallback: statusChangeCallback,
                                speakerId: speaker.id,
                              ),
                            if (!isEditable)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: STATUSCOLOR[speakerStatus]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(STATUSSTRING[speakerStatus]!),
                                  ),
                                ),
                              ),
                            //TODO define subscribe behaviour
                            ElevatedButton(
                                onPressed: () => print('zona'),
                                child: Text('+ Subscribe'))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _editSpeakerModal(context);
              },
            )
          ],
        );
      },
    );
  }
}

class SpeakerStatusDropdownButton extends StatelessWidget {
  final void Function(int, BuildContext) statusChangeCallback;
  final ParticipationStatus speakerStatus;
  final String speakerId;
  final SpeakerService _speakerService = SpeakerService();

  SpeakerStatusDropdownButton({
    Key? key,
    required this.statusChangeCallback,
    required this.speakerStatus,
    required this.speakerId,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _speakerService.getNextParticipationSteps(id: speakerId),
      builder: (context, snapshot) {
        List<ParticipationStep> steps = [
          ParticipationStep(next: speakerStatus, step: 0)
        ];
        if (snapshot.hasData) {
          steps.addAll(snapshot.data as List<ParticipationStep>);
        }
        return Container(
          child: DropdownButton<ParticipationStep>(
            underline: Container(
              height: 3,
              decoration: BoxDecoration(color: STATUSCOLOR[speakerStatus]),
            ),
            value: steps[0],
            style: Theme.of(context).textTheme.subtitle2,
            selectedItemBuilder: (BuildContext context) {
              return steps.map((e) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(child: Text(STATUSSTRING[e.next]!)),
                );
              }).toList();
            },
            items: steps
                .map((e) => DropdownMenuItem<ParticipationStep>(
                      value: e,
                      child: Text(STATUSSTRING[e.next] ?? ''),
                    ))
                .toList(),
            onChanged: (next) {
              if (next != null && next.step != 0) {
                statusChangeCallback(next.step, context);
              }
            },
          ),
        );
      },
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final Speaker speaker;
  const DetailsScreen({Key? key, required this.speaker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: EditableCard(
              title: 'Bio',
              body: speaker.bio ?? "",
              bodyEditedCallback: (newBio) {
                //speaker.bio = newBio;
                //TODO replace bio with service call to change bio
                print('replaced bio');
                return Future.delayed(Duration.zero);
              },
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: EditableCard(
              title: 'Notes',
              body: speaker.notes ?? "",
              bodyEditedCallback: (newNotes) {
                //speaker.bio = newBio;
                //TODO replace bio with service call to change bio
                print('replaced notes');
                return Future.delayed(Duration.zero);
              },
              isSingleline: false,
              textInputType: TextInputType.multiline,
            ),
          ),
        ],
      )),
    );
  }
}
