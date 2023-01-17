import 'package:flutter/material.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/session/DisplaySessionInfoScreens/SessionInformationBox.dart';

class DisplayTickets extends StatefulWidget {
  final Session session;
  const DisplayTickets({Key? key, required this.session}) : super(key: key);

  @override
  _DisplayTickets createState() => _DisplayTickets();
}

class _DisplayTickets extends State<DisplayTickets> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(186, 196, 242, 0.1),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          (widget.session.tickets == null)
              ? NoTicketsAvailable(widget.session)
              : TicketsAvailable(widget.session),
        ],
      ),
    );
  }

  Widget NoTicketsAvailable(Session session) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
                blurRadius: 7.0,
                color: Colors.grey.withOpacity(0.3),
                offset: new Offset(0, 3),
                spreadRadius: 4.0),
          ]),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Not Available",
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "No tickets were made available for this session.",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            )
          ],
        ),
      ]),
    );
  }

  Widget TicketsAvailable(Session session) {
    return Column(
      children: [
        SessionInformationBox(session: widget.session, type: "Max Tickets"),
        SessionInformationBox(session: widget.session, type: "Start Tickets"),
        SessionInformationBox(session: widget.session, type: "End Tickets"),
      ],
    );
  }
}
