import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/contact.dart';
import 'package:frontend/my_flutter_app_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class InformationBox extends StatelessWidget {
  final String title;
  final String type;
  final Contact contact;

  InformationBox(
      {Key? key,
      required this.title,
      required this.contact,
      required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (type == "mail") {
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
              for (int i = 0; i < contact.mails!.length; i++)
                ShowMail(mail: contact.mails![i]),
            ],
          ),
        ]),
      );
    } else if (type == "phone") {
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
              for (int i = 0; i < contact.phones!.length; i++)
                ShowPhone(phone: contact.phones![i]),
            ],
          ),
        ]),
      );
    } else if (type == "social") {
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
                  (contact.socials!.facebook != null)
                      ? IconButton(
                          icon: Icon(MyFlutterApp.facebook_circled),
                          iconSize: 35,
                          color: Color.fromRGBO(24, 119, 242, 1),
                          tooltip: contact.socials!.facebook,
                          onPressed: () {
                            launchURL("https://facebook.com/${contact.socials!.facebook}");
                          },
                        )
                      : Text(''),
                  (contact.socials!.github != null)
                      ? IconButton(
                          icon: const Icon(MyFlutterApp.github_circled),
                          iconSize: 35,
                          color: Color.fromRGBO(51, 51, 51, 1),
                          tooltip: contact.socials!.github,
                          onPressed: () {
                            launchURL(
                                "https://github.com/${contact.socials!.github}");
                          },
                        )
                      : Text(''),
                  (contact.socials!.twitter != null)
                      ? IconButton(
                          icon: const Icon(MyFlutterApp.twitter_circled),
                          iconSize: 35,
                          color: Color.fromRGBO(29, 161, 242, 1),
                          tooltip: contact.socials!.twitter,
                          onPressed: () {
                            launchURL(
                                "https://twitter.com/${contact.socials!.twitter}");
                          },
                        )
                      : Text(''),
                  (contact.socials!.skype != null)
                      ? IconButton(
                          icon: const Icon(MyFlutterApp.skype_circled),
                          iconSize: 35,
                          color: Color.fromRGBO(0, 175, 240, 1),
                          tooltip: contact.socials!.skype,
                          //FIXME: colocar launchURl para o skype
                          onPressed: () {},
                        )
                      : Text(''),
                  (contact.socials!.linkedin != null)
                      ? IconButton(
                          icon: const Icon(MyFlutterApp.linkedin_circled),
                          iconSize: 35,
                          color: Color.fromRGBO(10, 102, 194, 1),
                          tooltip: contact.socials!.linkedin,
                          onPressed: () {
                            launchURL(
                                "https://www.linkedin.com/in/${contact.socials!.linkedin}/");
                          },
                        )
                      : Text(''),
                ],
              )
            ],
          ),
        ]),
      );
    } else {
      return Container();
    }
  }

  ShowPhone({required ContactPhone phone}) {
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

  ShowMail({required ContactMail mail}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SelectableText(
          mail.mail!,
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
        Row(
          children: [
            mail.valid!
                ? Container()
                : Padding(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: Icon(Icons.report, color: Colors.red[300]),
                  ),
            mail.personal!
                ? Padding(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: Icon(Icons.house),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: Icon(Icons.work),
                  ),
          ],
        )
      ],
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
