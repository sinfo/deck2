import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';

class DeckDrawer extends StatefulWidget {
  String image;
  late bool _darkTheme;
  DeckDrawer({Key? key, required this.image}) : super(key: key) {
    _darkTheme = App.localStorage.getBool('darkTheme')!;
  }

  @override
  _DeckDrawerState createState() => _DeckDrawerState(image: this.image);
}

class _DeckDrawerState extends State<DeckDrawer> {
  late bool _darkTheme;
  final String image;

  _DeckDrawerState({required this.image});

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
          buildHeader(),
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
    await AuthService.signOut();
    Navigator.pushReplacementNamed(context, Routes.LoginRoute);
  }

  DrawerHeader buildHeader() {
    return DrawerHeader(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(this.image),
            ),
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
