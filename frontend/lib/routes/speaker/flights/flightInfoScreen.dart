import 'package:flutter/material.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/speaker/flights/participationFlightsWidget.dart';

class FlightInfoScreen extends StatefulWidget {
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
  _FlightInfoScreenState createState() => _FlightInfoScreenState();
}

class _FlightInfoScreenState extends State<FlightInfoScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: ListView(
            controller: ScrollController(),
            children: widget.participations.reversed
                .where((element) =>
                    element.flightsId != null && element.flightsId!.length != 0)
                .map(
                  (participation) => ParticipationFlightsWidget(
                    participation: participation,
                    id: widget.id,
                    small: widget.small,
                    onDelete: widget.onFlightDeleted,
                  ),
                )
                .toList()),
      );
    });
  }
}
