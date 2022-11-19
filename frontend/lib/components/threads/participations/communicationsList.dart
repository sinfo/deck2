import 'package:flutter/material.dart';
import 'package:frontend/components/threads/participations/participationThreadsWidget.dart';
import 'package:frontend/components/threads/threadCard/threadCard.dart';
import 'package:frontend/models/participation.dart';

class CommunicationsList extends StatelessWidget {
  final List<Participation> participations;
  // ID of the meeting/company/speaker
  final String id;
  final CommunicationType type;
  final bool small;

  CommunicationsList(
      {Key? key,
      required this.participations,
      required this.small,
      required this.type,
      required this.id})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: ListView(
            controller: ScrollController(),
            children: participations.reversed
                .where((element) =>
                    element.communicationsId != null &&
                    element.communicationsId!.length != 0)
                .map(
                  (participation) => ParticipationThreadsWidget(
                    participation: participation,
                    id: id,
                    type: type,
                    small: small,
                  ),
                )
                .toList()),
      );
    });
  }
}
