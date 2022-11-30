import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/session.dart';
import 'package:frontend/routes/session/EditSessionForm.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/sessionService.dart';
import 'package:provider/provider.dart';

class SessionBanner extends StatefulWidget {
  final Session session;

  const SessionBanner({Key? key, required this.session}) : super(key: key);

  @override
  _SessionBannerState createState() => _SessionBannerState();
}

class _SessionBannerState extends State<SessionBanner> {
  SessionService _sessionService = SessionService();
  String kind = "";

  @override
  void initState() {
    super.initState();
    if (widget.session.kind == "TALK") {
      setState(() {
        kind = "Talk";
      });
    } else if (widget.session.kind == "PRESENTATION") {
      setState(() {
        kind = "Presentation";
      });
    } else if (widget.session.kind == "WORKSHOP") {
      setState(() {
        kind = "Workshop";
      });
    }
  }

  void _deleteSessionDialog(context, id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog(
            'Warning', 'Are you sure you want to delete session?', () {
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
    setState(() {});
  }

  Future<void> _editSessionModal(context, id) async {
    Future<Session> sessionFuture = _sessionService.getSession(id);
    Session session = await sessionFuture;
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Container(
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/banner_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(height: 30),
            Text(kind,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(widget.session.title,
                style: TextStyle(
                    fontSize: 35,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () {
                      _editSessionModal(context, widget.session.id);
                    },
                    icon: Icon(Icons.edit),
                    color: Color.fromARGB(255, 201, 210, 237)),
                FutureBuilder(
                    future: Provider.of<AuthService>(context).role,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        Role r = snapshot.data as Role;

                        if (r == Role.ADMIN || r == Role.COORDINATOR) {
                          return IconButton(
                              onPressed: () => _deleteSessionDialog(
                                  context, widget.session.id),
                              icon: Icon(Icons.delete),
                              color: Colors.red);
                        } else {
                          return Container();
                        }
                      } else {
                        return Container();
                      }
                    }),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}
