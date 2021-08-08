import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/my_flutter_app_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class EditBoxSocials extends StatelessWidget {
  final String title;
  final String linkedin;
  final String twitter;
  final String skype;
  final String facebook;
  final String github;

  EditBoxSocials(
      {Key? key,
      required this.title,
      required this.facebook,
      required this.linkedin,
      required this.twitter,
      required this.skype,
      required this.github})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5)),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            Divider(),
            Row(
              children: [
                (facebook != "")
                    ? IconButton(
                        icon: Icon(MyFlutterApp.facebook_circled),
                        iconSize: 35,
                        color: Color.fromRGBO(24, 119, 242, 1),
                        tooltip: facebook,
                        onPressed: () {
                          launchURL("https://facebook.com/$facebook");
                        },
                      )
                    : Text(''),
                (github != "")
                    ? IconButton(
                        icon: const Icon(MyFlutterApp.github_circled),
                        iconSize: 35,
                        color: Color.fromRGBO(51, 51, 51, 1),
                        tooltip: facebook,
                        onPressed: () {
                          launchURL("https://github.com/$github");
                        },
                      )
                    : Text(''),
                (twitter != "")
                    ? IconButton(
                        icon: const Icon(MyFlutterApp.twitter_circled),
                        iconSize: 35,
                        color: Color.fromRGBO(29, 161, 242, 1),
                        tooltip: twitter,
                        onPressed: () {
                          launchURL("https://twitter.com/$twitter");
                        },
                      )
                    : Text(''),
                (skype != "")
                    ? IconButton(
                        icon: const Icon(MyFlutterApp.skype_circled),
                        iconSize: 35,
                        color: Color.fromRGBO(0, 175, 240, 1),
                        tooltip: skype,
                        //FIXME: colocar launchURl para o skype
                        onPressed: () {},
                      )
                    : Text(''),
                (linkedin != "")
                    ? IconButton(
                        icon: const Icon(MyFlutterApp.linkedin_circled),
                        iconSize: 35,
                        color: Color.fromRGBO(10, 102, 194, 1),
                        tooltip: linkedin,
                        onPressed: () {
                          launchURL("https://www.linkedin.com/in/$linkedin/");
                        },
                      )
                    : Text(''),
              ],
            )
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: Icon(Icons.edit,
              color: Color.fromRGBO(211, 211, 211, 1), size: 18),
        )
      ]),
    );
  }
}

launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url, forceWebView: true);
  } else {
    throw 'Could not launch $url';
  }
}
