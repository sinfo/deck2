import 'package:flutter/material.dart';
import 'package:frontend/components/threads/threadCard/threadCardBody.dart';
import 'package:frontend/components/threads/threadCard/threadCardHeader.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/models/post.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class FlightCard extends StatefulWidget {
  FlightInfo flight;
  final String id;
  final bool small;
  FlightCard(
      {Key? key, required this.flight, required this.small, required this.id})
      : super(key: key);

  @override
  _FlightCardState createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  Future<void> flightChangedCallback(BuildContext context,
      {FlightInfo? flight}) async {
    setState(() {
      widget.flight = flight!;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
          margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
          padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Departure: " + widget.flight.from),
              Text("Departure date: " + DateFormat('yyyy-MM-dd HH:mm').format(widget.flight.outbound)),
              Text("Arrival: " + widget.flight.to),
              Text("Arrival date: " + DateFormat('yyyy-MM-dd HH:mm').format(widget.flight.inbound)),
              Text("Flight link: " + widget.flight.link),
              Text("Flight bought? " + widget.flight.bought.toString()),
              Text("Flight cost: " + widget.flight.cost.toString()),
              Text("Flight notes:" + widget.flight.notes),
            ],
          ),
          ),
    );
  }
}
