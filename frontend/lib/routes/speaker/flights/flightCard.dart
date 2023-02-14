import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/models/flightInfo.dart';
import 'package:frontend/routes/speaker/flights/editFlightForm.dart';
import 'package:intl/intl.dart';

class FlightCard extends StatefulWidget {
  FlightInfo flight;
  final String id;
  final bool small;
  final void Function(String) onDelete;
  FlightCard(
      {Key? key,
      required this.flight,
      required this.small,
      required this.id,
      required this.onDelete})
      : super(key: key);

  @override
  _FlightCardState createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard>
    with AutomaticKeepAliveClientMixin {
  late NumberFormat formatter;
    
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    formatter = new NumberFormat("00");
  }

  Future<void> flightChangedCallback(BuildContext context,
      {FlightInfo? flight}) async {
    setState(() {
      widget.flight = flight!;
    });
  }

  void _editFlightModal(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditFlightForm(
                  flight: widget.flight,
                  onFlightEdit: (context, _flightInfo) {
                    flightChangedCallback(context, flight: _flightInfo);
                  }),
            ));
      },
    );
  }

  void _deleteFlightDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete flight ${widget.flight.from + "::" + DateFormat('yyyy-MM-dd HH:mm').format(widget.flight.outbound) + "->" + widget.flight.to + "::" + DateFormat('yyyy-MM-dd HH:mm').format(widget.flight.inbound)}?',
            () {
          widget.onDelete(widget.flight.id);
        });
      },
    );
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
                    style: TextStyle(
                        fontSize: widget.small ? 16 : 22,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            Clipboard.setData(
                                    ClipboardData(text: widget.flight.link))
                                .then((value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Copied flight link.',
                                        style: TextStyle(color: Colors.white))),
                              );
                            });
                          },
                          color: const Color(0xff5c7ff2),
                          icon: Icon(Icons.link)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            _editFlightModal(context);
                          },
                          color: const Color(0xff5c7ff2),
                          icon: Icon(Icons.edit)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            _deleteFlightDialog(context);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
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
                Column(
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
                Column(
                  children: [
                    Icon(Icons.monetization_on, size: 48),
                    Text(
                      (widget.flight.cost ~/ 100).toString() +
                          "." +
                          formatter.format(widget.flight.cost % 100),
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Price',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            widget.flight.notes != ""
                ? Text("Flight notes: " + widget.flight.notes,
                    textAlign: TextAlign.left, style: TextStyle(fontSize: 18))
                : Container(),
          ],
        ),
      ),
    );
  }
}
