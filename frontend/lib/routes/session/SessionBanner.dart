import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/deckTheme.dart';
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
      const SnackBar(
          content: Text('Deleting', style: TextStyle(color: Colors.white))),
    );

    Session? s = await _sessionService.deleteSession(id);
    if (s != null) {
      SessionsNotifier notifier =
          Provider.of<SessionsNotifier>(context, listen: false);
      notifier.remove(s);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Done', style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occured.',
                style: TextStyle(color: Colors.white))),
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
            heightFactor: 0.8,
            child: Container(
              child: EditSessionForm(session: session),
            ));
      },
    );
    setState(() {});
  }

  String getThreeDots(session) {
    if (session.title.length > 30) {
      return "...";
    } else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    int event = Provider.of<EventNotifier>(context).event.id;
    double lum = 0.2;
    var matrix = <double>[
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0.2126 * lum,
      0.7152 * lum,
      0.0722 * lum,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]; // Greyscale matrix. Lum represents level of luminosity
    return LayoutBuilder(builder: (context, constraints) {
      bool small = constraints.maxWidth < App.SIZE;
      return Container(
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: Provider.of<ThemeNotifier>(context).isDark
                ? ColorFilter.matrix(matrix)
                : null,
            image: AssetImage("assets/banner_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(height: 30),
            Text(kind,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SelectableText(
                widget.session.title.substring(
                        0,
                        widget.session.title.length < 30
                            ? widget.session.title.length
                            : 30) +
                    getThreeDots(widget.session),
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
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
