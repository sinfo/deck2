import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/drawer.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/CompanyListWidget.dart';
import 'package:frontend/routes/ThreadWidget.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/services/authService.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  late Future<Member?> _me;
  AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _me = checkSignInStatus();
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
                  label: 'Speakers',
                  icon: Icon(
                    Icons.star,
                  )),
              BottomNavigationBarItem(
                  label: 'Home',
                  icon: Icon(
                    Icons.home,
                  )),
              BottomNavigationBarItem(
                  label: 'Companies',
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
                Member me = snapshot.data as Member;
                return MyDrawer(image: me.image);
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
          return Center(child: ThreadListWidget());
        }
        break;
      case 1:
        {
          return Center(child: Text("Home in progress :)"));
        }
        break;
      case 2:
        {
          return Center(child: CompanyListWidget());
        }
        break;
      default:
        {
          return UnknownScreen();
        }
    }
  }

  Future<Member?> checkSignInStatus() async {
    bool isSignedIn = await googleSignIn.isSignedIn();
    if (!isSignedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      this._me = _authService.login();
      print(_me);
      return _me;
    }
  }
}
