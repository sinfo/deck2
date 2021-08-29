import 'package:flutter/material.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/HomeScreen.dart';
import 'package:frontend/routes/LoginScreen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Member?>(context);

    if (user == null) {
      return LoginScreen();
    } else {
      return HomeScreen();
    }
  }
}
