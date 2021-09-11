import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/meeting.dart';

class MeetingCard extends StatelessWidget {
  //final Meeting meeting;
  final List months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];

  MeetingCard({
    Key? key,
    /*required this.meeeting*/
  }) : super(key: key);

  String getTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String h = hour.toString();
    String m = minute.toString();
    if (hour < 10) {
      h = '0' + hour.toString();
    }
    if (minute < 10) {
      m = '0' + minute.toString();
    }

    return h + ':' + m;
  }

  String getDay(DateTime date) {
    return date.day.toString();
  }

  String getMonth(DateTime date) {
    int mon = date.month;
    return this.months[mon - 1];
  }

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
                      //child: Text(getDay(meeting.begin),
                      child: Text(getDay(DateTime.now()),
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                    ),
                    Container(
                      //child: Text(getMonth(meeting.begin),
                      child: Text(getMonth(DateTime.now()),
                          style: TextStyle(color: Colors.white, fontSize: 20)),
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
                        /*getTime(meeting.begin) +
                            ' - ' +
                            getTime(meeting.end()),*/
                        getTime(DateTime.now()) +
                            ' - ' +
                            getTime(DateTime.now()),
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
