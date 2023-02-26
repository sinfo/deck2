import 'package:flutter/material.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/routes/speaker/flights/flightCard.dart';

class ParticipationFlightsWidget extends StatelessWidget {
  final SpeakerParticipation participation;
  final String id;
  final bool small;
  final void Function(String) onDelete;

  ParticipationFlightsWidget(
      {Key? key,
      required this.participation,
      required this.small,
      required this.id,
      required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder(
        future: participation.flights,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error');
          }
          if (snapshot.connectionState == ConnectionState.done) {
            List<FlightInfo>? flightInfos = snapshot.data as List<FlightInfo>?;
            if (flightInfos == null) {
              flightInfos = [];
            }
            flightInfos.sort((a, b) => b.outbound.compareTo(a.outbound));
            return Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('SINFO ${participation.event}'),
                ),
              ),
              Divider(),
              ...flightInfos
                  .map(
                    (flightInfo) => FlightCard(
                      flight: flightInfo,
                      id: id,
                      onDelete: onDelete,
                    ),
                  )
                  .toList(),
            ]);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
