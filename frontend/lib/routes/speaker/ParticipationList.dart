import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/components/participationCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';
import 'package:provider/provider.dart';

class ParticipationList extends StatelessWidget {
  final Speaker speaker;
  final Future<void> Function(Map<String, dynamic>) onParticipationChanged;
  final Future<void> Function(ParticipationStatus) onChangePartStatus;
  final void Function() onParticipationDeleted;
  final void Function() onParticipationAdded;
  const ParticipationList({
    Key? key,
    required this.speaker,
    required this.onParticipationChanged,
    required this.onParticipationAdded,
    required this.onParticipationDeleted,
    required this.onChangePartStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      if (speaker.participations != null) {
        if (speaker.participations![speaker.participations!.length - 1].event ==
            Provider.of<EventNotifier>(context).latest.id) {
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
                              onChangeParticipationStatus: onChangePartStatus),
                        ))
                    .toList(),
              ),
            ),
          );
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
              child: ParticipationCard.addParticipationCard(onParticipationAdded),
            )
          );
      }
    });
  }
}
