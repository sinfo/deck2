//import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/sessions/EditSessionForm.dart';
import 'package:frontend/routes/sessions/SessionsNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final _sessionService = SessionService();

  SessionCard({Key? key, required this.session}) : super(key: key);

  void _editSessionModal(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditSessionForm(session: session),
            ));
      },
    );
  }

  void _deleteSessionDialog(context, id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete session ${session.title}?', () {
          _deleteSession(context, id);
        });
      },
    );
  }

  void _deleteSession(context, id) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting')),
    );

    Session? s = await _sessionService.deleteSession(id);
    if (s != null) {
      SessionsNotifier notifier =
          Provider.of<SessionsNotifier>(context, listen: false);
      notifier.remove(s);

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

 /*  void _uploadMeetingMinute(context) async {
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
          MeetingsNotifier notifier =
              Provider.of<MeetingsNotifier>(context, listen: false);
          notifier.edit(m);

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

  void _deleteMeetingMinuteDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete meeting minutes of ${meeting.title}?', () {
          _deleteMeetingMinute(context);
        });
      },
    );
  }

  void _deleteMeetingMinute(context) async {
    Meeting? m = await _meetingService.deleteMeetingMinute(meeting.id);
    if (m != null) {
      MeetingsNotifier notifier =
          Provider.of<MeetingsNotifier>(context, listen: false);
      notifier.edit(m);

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
  } */

  Widget _buildSessionCard(BuildContext context) {
    double _dateCardWidth = 120.0,
        _dateFontSize = 30.0,
        _titleFontSize = 23.0,
        _placeDateFontSize = 20.0,
        _cardMargin = 25.0,
        _dateMargins = 25.0,
        _iconsMargin = 8.0,
        _titleUpBottomMargin = 20.0,
        _titleLeftMargin = 15.0;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < App.SIZE) {
        _dateCardWidth = 50.0;
        _dateFontSize = 14.0;
        _titleFontSize = 16.0;
        _placeDateFontSize = 14.0;
      }
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        margin: EdgeInsets.all(_cardMargin),
        child: Stack(children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerLeft,
              // This child will fill full height, replace it with your leading widget
              child: Container(
                width: _dateCardWidth,
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: _dateMargins),
                      child: Text(
                        DateFormat.d().format(session.begin),
                        style: TextStyle(
                            color: Colors.white, fontSize: _dateFontSize),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: _dateMargins),
                      child: Text(
                        DateFormat.MMM().format(session.begin).toUpperCase(),
                        style: TextStyle(
                            color: Colors.white, fontSize: _dateFontSize),
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
            ),
          ),
          Row(
            children: <Widget>[
              SizedBox(width: _dateCardWidth),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      top: _titleUpBottomMargin,
                      bottom: _titleUpBottomMargin,
                      left: _titleLeftMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        child: Text(
                          session.title,
                          style: TextStyle(fontSize: _titleFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        child: Text(
                          session.place,
                          style: TextStyle(
                              color: Colors.grey, fontSize: _placeDateFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          DateFormat.jm().format(session.begin.toLocal()) +
                              ' - ' +
                              DateFormat.jm().format(session.end.toLocal()),
                          style: TextStyle(
                              color: Colors.grey, fontSize: _placeDateFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                    padding: EdgeInsets.all(_iconsMargin),
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
                                      _editSessionModal(context);
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
                                              onPressed: () => _deleteSessionDialog(
                                                  context, session.id),
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
/*                            if (DateTime.now().isAfter(session.begin))
                            ElevatedButton.icon(
                                onPressed: () => _uploadMeetingMinute(context),
                                icon: Icon(Icons.article),
                                style: ElevatedButton.styleFrom(
                                    primary: meeting.minute!.isNotEmpty
                                        ? const Color(0xFF5C7FF2)
                                        : Colors.green),
                                label: meeting.minute!.isNotEmpty
                                    ? const Text("Minutes")
                                    : const Text("Add Minutes")),
                          if (DateTime.now().isAfter(meeting.begin) &&
                              meeting.minute!.isNotEmpty)
                            Container(
                                margin: const EdgeInsets.only(top: 5.0),
                                child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _deleteMeetingMinuteDialog(context),
                                    icon: Icon(Icons.article),
                                    style: ElevatedButton.styleFrom(
                                        primary: const Color(0xFFF25C5C)),
                                    label: const Text("Delete Minutes"))) */
                        ])), 
              ),
            ],
          ),
        ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          print("go to session page"); //TODO
        },
        child: _buildSessionCard(context));
  }
}
