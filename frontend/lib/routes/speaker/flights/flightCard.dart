import 'package:flutter/material.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:intl/intl.dart';

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
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("From " + widget.flight.from + " to " + widget.flight.to,
                    textAlign: TextAlign.left,
                    style:
                        TextStyle(fontSize: widget.small ? 16 : 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            print("edit");
                          },
                          color: const Color(0xff5c7ff2),
                          icon: Icon(Icons.edit)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            print("delete");
                          },
                          color: Colors.red,
                          icon: Icon(Icons.delete)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color:
                              widget.flight.bought ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: EdgeInsets.all(widget.small ? 4.0 : 8.0),
                        child: Text(
                          widget.flight.bought
                              ? "Flight bought"
                              : "Flight not bought",
                          style: TextStyle(fontSize: widget.small ? 12 : 16),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            Divider(
              color: Colors.grey[600],
            ),
            Text(
                "Departure date: " +
                    DateFormat('yyyy-MM-dd HH:mm')
                        .format(widget.flight.outbound) +
                    "\nArrival date: " +
                    DateFormat('yyyy-MM-dd HH:mm')
                        .format(widget.flight.inbound) +
                    "\nFlight cost: " +
                    (widget.flight.cost ~/ 100).toString() +
                    "," +
                    (widget.flight.cost % 100).toString() +
                    "\nFlight link: " +
                    widget.flight.link +
                    "\nFlight notes:" +
                    widget.flight.notes,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
