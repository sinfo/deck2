import 'package:flutter/material.dart';
import 'package:frontend/routes/HomeScreen.dart';
import 'package:frontend/routes/LoginScreen.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/routes/WelcomeScreen.dart';

class Routes {
  static const String WelcomeRoute = '/';
  static const String LoginRoute = '/login';
  static const String HomeRoute = '/home';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.WelcomeRoute:
      return MaterialPageRoute(builder: (context) => WelcomeScreen());
    case Routes.LoginRoute:
      return MaterialPageRoute(builder: (context) => LoginScreen());
    case Routes.HomeRoute:
      return MaterialPageRoute(builder: (context) => HomeScreen());
    default:
      return MaterialPageRoute(builder: (context) => UnknownScreen());
  }
}
