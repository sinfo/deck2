import 'package:flutter/material.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/models/speaker.dart';
import 'package:frontend/services/speakerService.dart';
import 'package:intl/intl.dart';

class FlightCard extends StatefulWidget {
  final FlightInfo flight;
  late final Future<Speaker?> speaker;
  final SpeakerService speakerService = SpeakerService();

  FlightCard({Key? key, required this.flight}) : super(key: key);

  @override
  _FlightCardState createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard> {
  final NumberFormat formatter =  new NumberFormat("00");

  @override
  void initState() {
    super.initState();
  }

  getFlightStatus() {
    if (widget.flight.inbound.isBefore(DateTime.now())) {
      // return nothing
      return Text('');
    } else if (widget.flight.outbound.isBefore(DateTime.now()) && widget.flight.inbound.isAfter(DateTime.now())) {
      return Text('On the way', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    } else {
      return Text('Upcoming', style: TextStyle(color: Colors.blue));
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.speaker = widget.speakerService.getSpeaker(id: widget.flight.speaker);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FutureBuilder(
                      future: widget.speaker,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          Speaker speaker = snapshot.data as Speaker;
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(speaker.imgs!.speaker!),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      speaker.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      speaker.title!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          );
                        } else {
                          return Text("Loading speaker...");
                        }
                      }
                    )
                  ]
                ),
              ]
            ),
            Divider(
              color: Colors.grey[600],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Icon(Icons.flight_takeoff, size: 48),
                        Text(
                          widget.flight.from,
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(widget.flight.outbound),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Icon(Icons.flight_land, size: 48),
                        Text(
                          widget.flight.to,
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(widget.flight.inbound),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
        )
      )
    );
  }

}
