import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/drawer.dart';
import 'package:frontend/models/member.dart';
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
  Member me = null;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    checkSignInStatus();
    super.initState();
    _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _prefs,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Member me =
                Member.fromJson(json.decode(snapshot.data.getString("me")));
            print(me.id);

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
                drawer: MyDrawer(image: me.image));
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  Widget _pageAtIndex(int index) {
    // TODO: Build speakers, companies and home page
    return CircularProgressIndicator();
  }

  void checkSignInStatus() async {
    bool isSignedIn = await googleSignIn.isSignedIn();
    print(isSignedIn);
    if (!isSignedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      me = Member.fromJson(json.decode(prefs.getString('me')));
    }
  }
}
