import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/speaker/EditSpeakerForm.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class SpeakerScreen extends StatelessWidget {
  final Speaker speaker;
  const SpeakerScreen({Key? key, required this.speaker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(disableEventChange: true),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            SpeakerBanner(
              speaker: speaker,
            ),
            TabBar(
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.indigo[100],
              tabs: [
                Tab(text: 'Details'),
                Tab(text: 'FlightInfo'),
                Tab(text: 'Participations'),
                Tab(text: 'Communications'),
              ],
            ),
            Expanded(
              child: TabBarView(children: [
                DetailsScreen(
                  speaker: speaker,
                ),
                Container(
                  child: Center(child: Text('Work in progress :)')),
                ),
                Container(decoration: BoxDecoration(color: Colors.green)),
                Container(decoration: BoxDecoration(color: Colors.teal)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeakerBanner extends StatefulWidget {
  final Speaker speaker;
  const SpeakerBanner({Key? key, required this.speaker}) : super(key: key);

  @override
  _SpeakerBannerState createState() => _SpeakerBannerState();
}

class _SpeakerBannerState extends State<SpeakerBanner> {
  ParticipationStatus? previousStatus;
  late ParticipationStatus speakerStatus;

  void revertSpeakerStatus() {
    setState(() {
      speakerStatus = previousStatus!;
      //TODO call service method to change back participations status
    });
  }

  void changeSpeakerStatus(
      ParticipationStatus? newStatus, BuildContext context) {
    setState(() {
      previousStatus = speakerStatus;
      speakerStatus = newStatus!;
      //TODO call service method to change participations status
      final SnackBar snackBar = SnackBar(
        content: Text('Speaker status updated'),
        action: SnackBarAction(label: 'Undo', onPressed: revertSpeakerStatus),
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  Widget _buildSmallBanner(int event, ParticipationStatus speakerStatus) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/banner_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 20.0, 8.0),
              child: SizedBox(
                height: 100,
                width: 100,
                child: Hero(
                  tag: widget.speaker.id + event.toString(),
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 4,
                          color: STATUSCOLOR[speakerStatus]!,
                        )),
                    child: CircleAvatar(
                      foregroundImage: NetworkImage(
                        widget.speaker.imgs!.speaker ??
                            (widget.speaker.imgs!.internal ??
                                (widget.speaker.imgs!.company ?? "")),
                      ),
                      backgroundImage: AssetImage('assets/noImage.png'),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.speaker.name,
                      style: Theme.of(context).textTheme.headline6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(widget.speaker.title!,
                        style: Theme.of(context).textTheme.subtitle1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis),
                    SpeakerStatusDropdownButton(
                      speakerStatus: speakerStatus,
                      statusChangeCallback: changeSpeakerStatus,
                      speakerId: widget.speaker.id,
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
    );
  }

  Widget _buildBigBanner(int event, ParticipationStatus speakerStatus) {
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/banner_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 20.0, 8.0),
                  child: SizedBox(
                    height: 150,
                    width: 150,
                    child: Hero(
                      tag: widget.speaker.id + event.toString(),
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 4,
                              color: STATUSCOLOR[speakerStatus]!,
                            )),
                        child: CircleAvatar(
                          foregroundImage: NetworkImage(
                            widget.speaker.imgs!.speaker ??
                                (widget.speaker.imgs!.internal ??
                                    (widget.speaker.imgs!.company ?? "")),
                          ),
                          backgroundImage: AssetImage('assets/noImage.png'),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.speaker.name,
                          style: Theme.of(context).textTheme.headline5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(widget.speaker.title!,
                            style: Theme.of(context).textTheme.subtitle1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis),
                        SpeakerStatusDropdownButton(
                          speakerStatus: speakerStatus,
                          statusChangeCallback: changeSpeakerStatus,
                          speakerId: widget.speaker.id,
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () => Navigator.push(context,
                SlideRoute(page: EditSpeakerForm(speaker: widget.speaker))),
            child: Icon(Icons.edit),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    Participation? part = widget.speaker.participations!
        .firstWhereOrNull((element) => element.event == event);
    speakerStatus = part != null ? part.status! : ParticipationStatus.NO_STATUS;

    ParticipationStatus.NO_STATUS;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < App.SIZE) {
          return _buildSmallBanner(event, speakerStatus);
        } else {
          return _buildBigBanner(event, speakerStatus);
        }
      },
    );
  }
}

class SpeakerStatusDropdownButton extends StatelessWidget {
  final void Function(ParticipationStatus?, BuildContext) statusChangeCallback;
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
          child: DropdownButton<ParticipationStatus>(
            underline: Container(
              height: 3,
              decoration: BoxDecoration(color: STATUSCOLOR[speakerStatus]),
            ),
            value: speakerStatus,
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
                .map((e) => DropdownMenuItem<ParticipationStatus>(
                      value: e.next,
                      child: Text(STATUSSTRING[e.next] ?? ''),
                    ))
                .toList(),
            onChanged: (status) {
              if (status != speakerStatus) {
                statusChangeCallback(status, context);
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
