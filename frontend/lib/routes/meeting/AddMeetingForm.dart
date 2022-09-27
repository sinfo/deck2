import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';

class AddMeetingForm extends StatefulWidget {
  AddMeetingForm({Key? key}) : super(key: key);

  @override
  _AddMeetingFormState createState() => _AddMeetingFormState();
}

class _AddMeetingFormState extends State<AddMeetingForm> {
  @override
  Widget build(BuildContext context) {
    CustomAppBar appBar = CustomAppBar(
      disableEventChange: true,
    );
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: Center(child: Text("In Progress..."))),
        appBar,
      ]),
    );
  }
}
