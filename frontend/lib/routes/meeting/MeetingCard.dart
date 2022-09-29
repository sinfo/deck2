import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/routes/meeting/EditMeetingForm.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final _meetingService = MeetingService();

  MeetingCard({Key? key, required this.meeting}) : super(key: key);

  void _editMeetingModal(context) {
    //TODO: Update list of meetings after submit
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: EditMeetingForm(meeting: meeting),
        );
      },
    );
  }

  void _deleteMeeting(context, id) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting')),
    );

    Meeting? m = await _meetingService.deleteMeeting(id);
    if (m != null) {
      //TODO: Update list of meetings
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Done'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured.')),
      );
    }
  }

  void _uploadMeetingMinute(context) async {
    if (meeting.minute!.isNotEmpty) {
      Uri uri = Uri.parse(meeting.minute!);
      if (!await launchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error downloading minutes')),
        );
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading')),
        );

        PlatformFile minute = result.files.first;

        Meeting? m = await _meetingService.uploadMeetingMinute(
            id: meeting.id, minute: minute);

        if (m != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Done'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occured.')),
          );
        }
      }
    }
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
          height: 125.0,
          child: Row(
            children: <Widget>[
              Container(
                height: 150.0,
                width: 120.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 25.0),
                      child: Text(
                        DateFormat.d().format(meeting.begin),
                        style: TextStyle(color: Colors.white, fontSize: 30.0),
                      ),
                    ),
                    Container(
                      child: Text(
                        DateFormat.MMM().format(meeting.begin).toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 30.0),
                      ),
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
                        meeting.title,
                        style: TextStyle(color: Colors.black, fontSize: 23.0),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      child: Text(
                        meeting.place,
                        style: TextStyle(color: Colors.grey, fontSize: 20.0),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text(
                        DateFormat.jm().format(meeting.begin.toLocal()) +
                            ' - ' +
                            DateFormat.jm().format(meeting.end.toLocal()),
                        style: TextStyle(color: Colors.grey, fontSize: 20.0),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      _editMeetingModal(context);
                                    },
                                    icon: Icon(Icons.edit),
                                    color: const Color(0xff5c7ff2)),
                                FutureBuilder(
                                    future:
                                        Provider.of<AuthService>(context).role,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        Role r = snapshot.data as Role;

                                        if (r == Role.ADMIN ||
                                            r == Role.COORDINATOR) {
                                          return IconButton(
                                              onPressed: () => _deleteMeeting(
                                                  context, meeting.id),
                                              icon: Icon(Icons.delete),
                                              color: Colors.red);
                                        } else {
                                          return Container();
                                        }
                                      } else {
                                        return Container();
                                      }
                                    })
                              ]),
                          if (DateTime.now().isAfter(meeting.begin))
                            ElevatedButton.icon(
                                //TODO: Do the upload meeting minutes endpoint
                                onPressed: () => _uploadMeetingMinute(context),
                                icon: Icon(Icons.article),
                                style: ElevatedButton.styleFrom(
                                    primary: meeting.minute!.isNotEmpty
                                        ? const Color(0xFF5C7FF2)
                                        : const Color(0xFFF25C5C)),
                                label: meeting.minute!.isNotEmpty
                                    ? const Text("Minutes")
                                    : const Text("Add Minutes"))
                        ])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
