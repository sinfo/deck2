import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/drawer.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/authService.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex;
  GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  Future<Member> _me;
  AuthService _authService = AuthService();

  @override
  void initState() {
    checkSignInStatus();
    super.initState();
    _currentIndex = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(),
        bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            // Give a custom drawer header
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  title: Text('Speakers'),
                  icon: Icon(
                    Icons.star,
                  )),
              BottomNavigationBarItem(
                  title: Text('Home'),
                  icon: Icon(
                    Icons.home,
                  )),
              BottomNavigationBarItem(
                  title: Text('Companies'),
                  icon: Icon(
                    Icons.work,
                  ))
            ],
            onTap: (newIndex) {
              setState(() {
                _currentIndex = newIndex;
              });
            }),
        body: _pageAtIndex(_currentIndex),
        drawer: FutureBuilder(
            future: _me,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return MyDrawer(image: snapshot.data.image);
              } else {
                return CircularProgressIndicator();
              }
            }));
  }

  Widget _pageAtIndex(int index) {
    // TODO: Build speakers, companies and home page
    switch (index) {
      case 0:
        {
          return Center(child: Text("Speakers in progress :)"));
        }
        break;
      case 1:
        {
          return Center(child: Text("Home in progress :)"));
        }
        break;
      case 2:
        {
          return Center(child: Text("Companies in progress :)"));
        }
        break;
    }
  }

  void checkSignInStatus() async {
    bool isSignedIn = await googleSignIn.isSignedIn();
    if (!isSignedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        _me = _authService.login();
      });
    }
  }
}
