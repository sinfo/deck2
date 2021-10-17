
  
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
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
          ListTile(
              leading: Icon(
                Icons.person,
              ),
              title: Text('Logout'),
              onTap: () async {
                await signOut(context);
              }),
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
    await Provider.of<AuthService>(context).signOut();
    Navigator.pushReplacementNamed(context, Routes.LoginRoute);
  }

  DrawerHeader buildHeader(BuildContext context) {
    return DrawerHeader(
        margin: EdgeInsets.zero,
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
                    );
                  } else {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[400]!,
                      highlightColor: Colors.white,
                      child: CircleAvatar(),
                    );
                  }
                }),
            Text(
              "My Account",
              style: TextStyle(
                fontSize: 22,
              ),
            ),
          ],
        ));
  }
}