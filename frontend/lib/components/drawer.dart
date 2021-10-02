import 'package:flutter/material.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/services/authService.dart';

class MyDrawer extends Drawer {
  String image;
  MyDrawer({Key? key, required this.image});

  @override
  Drawer build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        buildHeader(),
        ListTile(
          leading: Icon(
            Icons.settings,
          ),
          title: Text('Settings Page'),
        ),
        ListTile(
            leading: Icon(
              Icons.person,
            ),
            title: Text('Logout'),
            onTap: () async {
              await signOut(context);
            }),
        ListTile(
          leading: Icon(
            Icons.library_books,
          ),
          title: Text('Library Page'),
        ),
        ListTile(
          leading: Icon(
            Icons.help,
          ),
          title: Text('Help Page'),
        ),
        ListTile(
          leading: Icon(
            Icons.notifications,
          ),
          title: Text('Notifications'),
        )
      ],
    ));
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
