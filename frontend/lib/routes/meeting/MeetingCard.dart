import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/meeting.dart';
import 'package:intl/intl.dart';

class MeetingCard extends StatelessWidget {
  //final Meeting meeting;

  MeetingCard({
    Key? key,
    /*required this.meeeting*/
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("go to meeting page"); //TODO
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        margin: EdgeInsets.all(25.0),
        child: Container(
          height: 100.0,
          child: Row(
            children: <Widget>[
              Container(
                height: 100.0,
                width: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 20.0),
                      // child: Text(DateFormat.d().format(meeting.begin),
                      child: Text(DateFormat.d().format(DateTime.now()),
                          style: TextStyle(color: Colors.white, fontSize: 22)),
                    ),
                    Container(
                      // child: Text(DateFormat.MMM().format(meeting.begin),
                      child: Text(DateFormat.MMM().format(DateTime.now()),
                          style: TextStyle(color: Colors.white, fontSize: 22)),
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(5.0),
                      topLeft: Radius.circular(5.0)),
                  image: DecorationImage(
                    image: AssetImage("assets/banner_background.png"),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 15.0, top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text(
                        "Zoom",
                        /*Text(meeting.place,*/
                        style: TextStyle(color: Colors.black, fontSize: 23.0),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text(
                        /*DateFormat.jm().format(meeting.begin) +
                            ' - ' +
                            DateFormat.jm().format(meeting.end),*/
                        DateFormat.jm().format(DateTime.now()) +
                            ' - ' +
                            DateFormat.jm().format(DateTime.now()),
                        style: TextStyle(color: Colors.grey, fontSize: 20.0),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
