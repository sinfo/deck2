import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/routes/items_packages/ItemPackagePage.dart';
import 'package:frontend/routes/meeting/MeetingPage.dart';
import 'package:frontend/routes/members_teams/member/MemberPage.dart';
import 'package:frontend/routes/members_teams/member/MemberScreen.dart';
import 'package:frontend/routes/session/SessionPage.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DeckDrawer extends StatefulWidget {
  DeckDrawer({Key? key}) : super(key: key);

  @override
  _DeckDrawerState createState() => _DeckDrawerState();
}

class _DeckDrawerState extends State<DeckDrawer> {
  late bool _darkTheme;

  _DeckDrawerState();

  @override
  void initState() {
    _darkTheme = App.localStorage.getBool('darkTheme') == null
        ? false
        : App.localStorage.getBool('darkTheme')!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          buildHeader(context),
          Container(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                "Me",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.start,
              ),
            ),
          ),
          MergeSemantics(
            child: ListTile(
              leading: Icon(
                Icons.dark_mode,
              ),
              title: const Text('Dark mode'),
              trailing: CupertinoSwitch(
                value: _darkTheme,
                onChanged: (bool value) {
                  setState(() {
                    _darkTheme = value;
                  });
                  onThemeChanged(value, themeNotifier);
                },
              ),
              onTap: () {
                setState(() {
                  _darkTheme = !_darkTheme;
                  onThemeChanged(_darkTheme, themeNotifier);
                });
              },
            ),
          ),
          FutureBuilder(
              future: Provider.of<AuthService>(context).user,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Member m = snapshot.data as Member;
                  return ListTile(
                    leading: Icon(
                      Icons.person,
                    ),
                    title: Text('My Profile'),
                    onTap: () async {
                      myProfile(context, m);
                    },
                  );
                } else {
                  return ListTile(
                    leading: Icon(
                      Icons.person,
                    ),
                    title: Text('My Profile'),
                    onTap: () async {},
                  );
                }
              }),
          ListTile(
              leading: Icon(
                Icons.logout,
              ),
              title: Text('Logout'),
              onTap: () async {
                await signOut(context);
              }),
          Divider(),
          Container(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                "Management",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.start,
              ),
            ),
          ),
          ListTile(
              leading: Icon(
                Icons.store,
              ),
              title: Text('Manage items/packages'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ItemPackagePage(),
                    ));
              }),
          ListTile(
              leading: Icon(
                Icons.people,
              ),
              title: Text('Members and teams'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          MemberPage(),
                    ));
              }),
          ListTile(
              leading: Icon(
                Icons.meeting_room,
              ),
              title: Text('Meetings'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          MeetingPage(),
                    ));
              }),
          ListTile(
              leading: Icon(
                Icons.co_present,
              ),
              title: Text('Sessions'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SessionPage(),
                    ));
              }),
          Divider(),
          Container(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                "Utils",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.start,
              ),
            ),
          ),
          ListTile(
              leading: Icon(
                Icons.receipt,
              ),
              title: Text('All billings'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          UnknownScreen(), //TODO: All billings screen
                    ));
              }),
          ListTile(
              leading: Icon(
                Icons.flight,
              ),
              title: Text('All flights'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          UnknownScreen(), //TODO: All flights screen
                    ));
              }),
          ListTile(
              leading: Icon(
                Icons.shopping_cart,
              ),
              title: Text('All items'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          UnknownScreen(), //TODO: All items screen
                    ));
              }),
          ListTile(
              leading: Icon(
                Icons.local_convenience_store,
              ),
              title: Text('All packages'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 600),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          UnknownScreen(), //TODO: All packages screen
                    ));
              }),
        ],
      ),
    );
  }

  void onThemeChanged(bool value, ThemeNotifier themeNotifier) async {
    (value)
        ? themeNotifier.setTheme(DarkTheme())
        : themeNotifier.setTheme(LightTheme());
    App.localStorage.setBool('darkTheme', value);
  }

  Future signOut(BuildContext context) async {
    await Provider.of<AuthService>(context, listen: false).signOut();
    Navigator.pushReplacementNamed(context, Routes.LoginRoute);
  }

  myProfile(BuildContext context, Member member) {
    Navigator.pop(context);
    Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              MemberScreen(member: member),
        ));
  }

  DrawerHeader buildHeader(BuildContext context) {
    return DrawerHeader(
        margin: EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder(
                future: Provider.of<AuthService>(context).user,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Member m = snapshot.data as Member;
                    return CircleAvatar(
                      backgroundImage: NetworkImage(m.image!),
                      radius: 40,
                    );
                  } else {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[400]!,
                      highlightColor: Colors.white,
                      child: CircleAvatar(),
                    );
                  }
                }),
            FutureBuilder(
                future: Provider.of<AuthService>(context).user,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    Member m = snapshot.data as Member;
                    return Text(
                      "Hello, " + m.name,
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    );
                  } else {
                    return Text(
                      "My Account",
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    );
                  }
                }),
          ],
        ));
  }
}
