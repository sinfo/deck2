import 'package:flutter/material.dart';
import 'package:frontend/components/threads/participations/participationThreadsWidget.dart';
import 'package:frontend/models/participation.dart';

class CommunicationsList extends StatelessWidget {
  final List<Participation> participations;
  final bool small;
  final void Function(String) onCommunicationDeleted;

  CommunicationsList(
      {Key? key,
      required this.participations,
      required this.small,
      required this.onCommunicationDeleted})
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
                    small: small,
                    onCommunicationDeleted: onCommunicationDeleted,
                  ),
                )
                .toList()),
      );
    });
  }
}
