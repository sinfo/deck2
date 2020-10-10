import 'package:flutter/material.dart';
import 'package:frontend/components/router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WelcomeScreen extends StatefulWidget {
  WelcomeScreen({Key key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  GoogleSignIn googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");

  @override
  void initState() {
    checkSignInStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.indigo,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image(image: AssetImage("assets/logo-branco2.png"))
            ],
          ),
        ),
      ),
    );
  }

  void checkSignInStatus() async {
    bool isSignedIn = await googleSignIn.isSignedIn();
    if (!isSignedIn) {
      Navigator.pushReplacementNamed(context, Routes.LoginRoute);
    } else {
      Navigator.pushNamed(context, Routes.HomeRoute);
    }
  }
}
