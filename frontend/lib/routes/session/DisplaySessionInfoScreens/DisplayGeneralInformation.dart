import 'package:flutter/material.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/session/DisplaySessionInfoScreens/SessionInformationBox.dart';
import 'package:frontend/services/contactService.dart';

class DisplayGeneralInformation extends StatefulWidget {
  final Session session;
  const DisplayGeneralInformation({Key? key, required this.session})
      : super(key: key);

  @override
  _DisplayGeneralInformation createState() => _DisplayGeneralInformation();
}

class _DisplayGeneralInformation extends State<DisplayGeneralInformation> {
  ContactService contactService = new ContactService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        physics: BouncingScrollPhysics(),
        children: [
          SessionInformationBox(session: widget.session, type: "Begin Session"),
          SessionInformationBox(session: widget.session, type: "End Session"),
          SessionInformationBox(session: widget.session, type: "description"),
          SessionInformationBox(session: widget.session, type: "place"),
          SessionInformationBox(session: widget.session, type: "videoURL"),
        ],
      ),
    );
  }
}
