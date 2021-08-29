import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/drawer.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/CompanyListWidget.dart';
import 'package:frontend/routes/company/CompanyTable.dart';
import 'package:frontend/routes/MemberListWidget.dart';
import 'package:frontend/routes/speaker/SpeakerTable.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/services/authService.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  AuthService _authService = AuthService();

  @override
  void initState() {
    checkSignInStatus();
    _currentIndex = 1;
    App.localStorage.setInt("event", 29);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Member?>(context);

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
      drawer: MyDrawer(image: user != null ? user.image : ''),
      floatingActionButton: _fabAtIndex(_currentIndex),
    );
  }

  Widget? _fabAtIndex(int index) {
    switch (index) {
      case 0:
        {
          return FloatingActionButton(
            onPressed: () => {},
            tooltip: 'Add Speaker',
            child: const Icon(Icons.add),
          );
        }
      case 1:
        {
          return null;
        }
      case 2:
        {
          return FloatingActionButton(
            onPressed: () => {Navigator.pushNamed(context, Routes.AddCompany)},
            tooltip: 'Add Company',
            child: const Icon(Icons.add),
          );
        }
    }
  }

  Widget _pageAtIndex(int index) {
    // TODO: Build speakers, companies and home page
    switch (index) {
      case 0:
        {
          return Center(child: SpeakerTable());
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
    bool isSignedIn = await _authService.isLoggedIn();
    if (!isSignedIn) {
      Navigator.pushReplacementNamed(context, Routes.LoginRoute);
    }
  }
}
