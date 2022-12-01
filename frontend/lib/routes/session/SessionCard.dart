import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/session/EditSessionForm.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final _sessionService = SessionService();

  double _dateCardWidth = 120.0,
      _dateFontSize = 30.0,
      _titleFontSize = 23.0,
      _descriptionFontSize = 15.0,
      _placeDateFontSize = 20.0,
      _cardMargin = 25.0,
      _dateMargins = 25.0,
      _iconsMargin = 8.0,
      _titleUpBottomMargin = 5.0,
      _titleLeftMargin = 15.0;

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

  Widget _buildSessionCard(BuildContext context) {
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
            side: BorderSide(color: Colors.indigo, width: 2)),
        margin: EdgeInsets.all(_cardMargin),
        child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
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
                            DateFormat.MMM()
                                .format(session.begin)
                                .toUpperCase(),
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
                buildText(context)
              ],
            )),
      );
    });
  }

  Widget buildText(BuildContext context) {
    final DateTime? _beginTicket = session.tickets?.start;
    final DateTime? _endTicket = session.tickets?.end;
    final String? _maxTickets = session.tickets?.max.toString();

    return ExpansionTile(
      // childrenPadding: EdgeInsets.all(16),
      title: Text(
        session.title,
        style: TextStyle(fontSize: _titleFontSize),
        textAlign: TextAlign.left,
      ),
      children: [
        Stack(alignment: AlignmentDirectional.topStart, children: [
          Row(
            children: <Widget>[
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
                        margin: EdgeInsets.only(bottom: _titleUpBottomMargin),
                        child: Text(
                          session.kind,
                          style: TextStyle(fontSize: _titleFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            top: _titleUpBottomMargin,
                            bottom: _titleUpBottomMargin),
                        child: Text(
                          session.description,
                          style: TextStyle(fontSize: _descriptionFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            top: _titleUpBottomMargin,
                            bottom: _titleUpBottomMargin),
                        child: Text(
                          session.place ?? 'No place available yet',
                          style: TextStyle(fontSize: _placeDateFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          DateFormat.jm().format(session.begin.toLocal()) +
                              ' - ' +
                              DateFormat.jm().format(session.end.toLocal()),
                          style: TextStyle(fontSize: _placeDateFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        child: Text(
                          session.videoURL ?? 'No video available yet',
                          style: TextStyle(fontSize: _placeDateFontSize),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        child: (session.tickets != null)
                            ? Container(
                                padding:
                                    EdgeInsets.only(top: 5.0, bottom: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tickets',
                                      style: TextStyle(
                                          fontSize: _placeDateFontSize),
                                      textAlign: TextAlign.left,
                                    ),
                                    Text(
                                      'Available from ' +
                                          DateFormat.yMd()
                                              .add_jm()
                                              .format(_beginTicket!.toLocal()) +
                                          ' to ' +
                                          DateFormat.yMd()
                                              .add_jm()
                                              .format(_endTicket!.toLocal()),
                                      style: TextStyle(fontSize: 15.0),
                                      textAlign: TextAlign.left,
                                    ),
                                    Text(
                                      'Quantity: ' + _maxTickets!,
                                      style: TextStyle(fontSize: 15.0),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ))
                            : null,
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
                                              onPressed: () =>
                                                  _deleteSessionDialog(
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
                        ])),
              ),
            ],
          ),
        ]),
      ],
    );
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
