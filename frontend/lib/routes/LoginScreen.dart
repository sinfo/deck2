import 'package:flutter/material.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/services/authService.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  AuthService _authService = AuthService();
  Future<bool>? isLoggedIn;

  @override
  void initState() {
    isLoggedIn = tryLogin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage("assets/banner_background.png"))),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/logo-branco2.png'),
                height: 150,
                width: 700,
              ),
              SizedBox(height: 200),
              _signInButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signInButton() {
    return FutureBuilder(
        future: isLoggedIn,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            bool loggedIn = snapshot.data as bool;
            if (loggedIn) {
              return CircularProgressIndicator();
            } else {
              return OutlinedButton(
                onPressed: () {
                  stateSignIn();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                    side: BorderSide(color: Colors.blue),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image(
                          image: AssetImage("assets/google_logo.png"),
                          height: 35.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  Future<bool> tryLogin() async {
    bool loggedIn = await _authService.loginSilent();
    if (loggedIn) {
      Navigator.pushReplacementNamed(context, Routes.HomeRoute);
      return true;
    }
    return false;
  }

  void stateSignIn() async {
    bool loggedIn = await _authService.login();
    if (loggedIn) {
      Navigator.pushReplacementNamed(context, Routes.HomeRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Could not login. Please try again or contact admins.')),
      );
    }
  }
}
