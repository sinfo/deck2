import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';
import 'package:provider/provider.dart';

import '../../services/speakerService.dart';

class ParticipationList extends StatelessWidget {
  final Speaker speaker;
  final Future<void> Function(Map<String, dynamic>) onParticipationChanged;
  final Future<void> Function(ParticipationStatus) onChangePartStatus;
  final void Function() onParticipationDeleted;
  final void Function() onParticipationAdded;
  final void Function(int, BuildContext) statusChangeCallback;
  final SpeakerService _speakerService = SpeakerService();

  ParticipationList({
    Key? key,
    required this.statusChangeCallback,
    required this.speaker,
    required this.onParticipationChanged,
    required this.onParticipationAdded,
    required this.onParticipationDeleted,
    required this.onChangePartStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<ParticipationStep> steps = [
      ParticipationStep(next: speaker.participationStatus!, step: 0)
    ];
    // Future<Object?> myFuture = fetchDataFromNetwork();

    // Create a FutureBuilder widget using the defined future variable
    // var futureBuilder = FutureBuilder<Object?>(
    //   future: _speakerService.getNextParticipationSteps(id: speaker.id),
    //   builder: (context, snapshot) {
    //     if (snapshot.hasData) {
    //       steps.addAll(snapshot.data as List<ParticipationStep>);
    //     }
    //   },
    // );

    int event = Provider.of<EventNotifier>(context).event.id;

    Participation? part = speaker.participations!
        .firstWhereOrNull((element) => element.event == event);
    ParticipationStatus speakerStatus =
        part != null ? part.status : ParticipationStatus.NO_STATUS;
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      if (speaker.participations != null) {
        if (speaker.participations![speaker.participations!.length - 1].event ==
            Provider.of<EventNotifier>(context).latest.id) {
          return FutureBuilder(
              future: _speakerService.getNextParticipationSteps(id: speaker.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  steps.addAll(snapshot.data as List<ParticipationStep>);
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    child: ListView(
                      controller: ScrollController(),
                      children: speaker.participations!.reversed
                          .map((e) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ParticipationCard(
                                    // speaker: speaker,
                                    steps: steps,
                                    speakerStatus: speakerStatus,
                                    speakerId: speaker.id,
                                    participation: e,
                                    small: small,
                                    type: CardType.SPEAKER,
                                    onEdit: onParticipationChanged,
                                    onDelete: onParticipationDeleted,
                                    onChangeParticipationStatus:
                                        onChangePartStatus),
                              ))
                          .toList(),
                    ),
                  ),
                );
              });
          // return Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Container(
          //     child: ListView(
          //       controller: ScrollController(),
          //       children: speaker.participations!.reversed
          //           .map((e) => Padding(
          //                 padding: const EdgeInsets.all(8.0),
          //                 child: ParticipationCard(
          //                     // speaker: speaker,
          //                     steps: steps,
          //                     speakerStatus: speakerStatus,
          //                     speakerId: speaker.id,
          //                     participation: e,
          //                     small: small,
          //                     type: CardType.SPEAKER,
          //                     onEdit: onParticipationChanged,
          //                     onDelete: onParticipationDeleted,
          //                     onChangeParticipationStatus: onChangePartStatus),
          //               ))
          //           .toList(),
          //     ),
          //   ),
          // );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ParticipationCard.addParticipationCard(
                        onParticipationAdded),
                  ),
                  ...speaker.participations!.reversed
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ParticipationCard(
                                participation: e,
                                small: small,
                                type: CardType.SPEAKER),
                          ))
                      .toList(),
                ],
              ),
            ),
          );
        }
      } else {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  ParticipationCard.addParticipationCard(onParticipationAdded),
            ));
      }
    });
  }
}
