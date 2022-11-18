import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/my_flutter_app_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionInformationBox extends StatelessWidget {
  // final String title;
  final Session session;
  // final String description;
  final String type;

  SessionInformationBox({Key? key, required this.session, required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (type == "description") {
      return Container(
        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Colors.white,
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
              Text("Description",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              Divider(),
              showInfo(info: session.description),
            ],
          ),
        ]),
      );
    } else if (type == "kind") {
      return Container(
        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Colors.white,
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
              Text("Kind",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              Divider(),
              showInfo(info: session.kind),
            ],
          ),
        ]),
      );
    } else if (type == "videoURL") {
      return Container(
        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Colors.white,
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
              Text("VideoURL",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              Divider(),
              showInfo(info: session.videoURL!),
            ],
          ),
        ]),
      );
    } else if (type == "place") {
      return Container(
        margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Colors.white,
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
              Text("Place",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              Divider(),
              showInfo(info: session.place!),
            ],
          ),
        ]),
      );
    } else {
      return Container();
    }
  }

  Widget showPhone({required ContactPhone phone}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SelectableText(
          phone.phone!,
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            phone.valid!
                ? Container()
                : Icon(
                    Icons.report,
                    color: Colors.red[300],
                  ),
          ],
        )
      ],
    );
  }

  Widget showInfo({required String info}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          info,
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }
}

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url, forceWebView: true);
  } else {
    throw 'Could not launch $url';
  }
}
