import 'package:flutter/material.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/speaker/flights/participationFlightsWidget.dart';

class FlightInfoScreen extends StatelessWidget {
  final List<SpeakerParticipation> participations;
  final String id;
  final bool small;
  final void Function(String) onFlightDeleted;
  const FlightInfoScreen(
      {Key? key,
      required this.participations,
      required this.small,
      required this.onFlightDeleted,
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
                    element.flightsId != null && element.flightsId!.length != 0)
                .map(
                  (participation) => ParticipationFlightsWidget(
                    participation: participation,
                    id: id,
                    small: small,
                    onDelete: onFlightDeleted,
                  ),
                )
                .toList()),
      );
    });
  }
}
