import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/drawer.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/CompanyListWidget.dart';
import 'package:frontend/routes/CompanyTable.dart';
import 'package:frontend/routes/MemberListWidget.dart';
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
    _me = checkSignInStatus();
    _currentIndex = 1;
    App.localStorage.setInt("event", 29);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(),
        bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
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
                  )),
              //FIXME: o item aqui em baixo foi colocado apenas para processo de development
              BottomNavigationBarItem(
                  label: 'Members',
                  icon: Icon(
                    Icons.people,
                  )),
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
          return Center(child: CompanyTable());
        }
        break;
      //FIXME: retirar isto em baixo porque não vai ficar aqui
      case 3:
        {
          return Center(child: MemberListWidget());
        }
        break;
      default:
        {
          return UnknownScreen();
        }
    }
  }

  Future<Member?> checkSignInStatus() async {
    await googleSignIn.signInSilently();
    bool isSignedIn = await googleSignIn.isSignedIn();
    if (!isSignedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      this._me = _authService.login();
      return _me;
    }
  }
}
