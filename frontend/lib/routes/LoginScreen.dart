import 'package:flutter/material.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/authService.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<Member?>? user;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }

  Widget _signInButton() {
    return FutureBuilder(
        future: user,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Member? m = snapshot.data as Member?;
            if (m != null) {
              print('\nloggedin: ${m.name}');
            }
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
        });
  }

  // Future<bool> tryLogin() async {
  //   bool loggedIn = await AuthService.loginSilent();
  //   if (loggedIn) {
  //     return true;
  //   }
  //   return false;
  // }

  void stateSignIn() async {
    bool loggedIn = await AuthService.login();
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
