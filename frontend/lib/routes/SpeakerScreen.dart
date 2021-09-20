import 'package:flutter/material.dart';
import 'package:frontend/components/EditableCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:provider/provider.dart';

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
                Container(decoration: BoxDecoration(color: Colors.amber)),
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

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    speakerStatus = widget.speaker.participations!
            .firstWhere((element) => element.event == event)
            .status ??
        ParticipationStatus.NO_STATUS;
    return Container(
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
}

class SpeakerStatusDropdownButton extends StatelessWidget {
  final void Function(ParticipationStatus?, BuildContext) statusChangeCallback;
  final ParticipationStatus speakerStatus;
  const SpeakerStatusDropdownButton(
      {Key? key,
      required this.statusChangeCallback,
      required this.speakerStatus})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: DropdownButton<ParticipationStatus>(
        underline: Container(
          height: 3,
          decoration: BoxDecoration(color: Theme.of(context).accentColor),
        ),
        value: speakerStatus,
        style: Theme.of(context).textTheme.subtitle2,
        selectedItemBuilder: (BuildContext context) {
          //TODO get next possible steps, instead of all values
          return ParticipationStatus.values.map((e) {
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(child: Text(STATUSSTRING[e]!)),
            );
          }).toList();
        },
        items: ParticipationStatus.values
            .map((e) => DropdownMenuItem<ParticipationStatus>(
                  value: e,
                  child: Text(STATUSSTRING[e]!),
                ))
            .toList(),
        onChanged: (status) {
          statusChangeCallback(status, context);
        },
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final Speaker speaker;
  const DetailsScreen({Key? key, required this.speaker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              return Future.delayed(Duration(seconds: 30));
            },
            isSingleline: false,
            textInputType: TextInputType.multiline,
          ),
        ),
      ],
    ));
  }
}
