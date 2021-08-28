import 'package:flutter/material.dart';
import 'package:frontend/routes/HomeScreen.dart';
import 'package:frontend/routes/LoginScreen.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/routes/WelcomeScreen.dart';
import 'package:frontend/routes/company/AddCompanyForm.dart';

class Routes {
  static const String WelcomeRoute = '/';
  static const String LoginRoute = '/login';
  static const String HomeRoute = '/home';
  static const String AddCompany = '/add/company';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.WelcomeRoute:
      return MaterialPageRoute(builder: (context) => WelcomeScreen());
    case Routes.LoginRoute:
      return MaterialPageRoute(builder: (context) => LoginScreen());
    case Routes.HomeRoute:
      return MaterialPageRoute(builder: (context) => HomeScreen());
    case Routes.AddCompany:
      return MaterialPageRoute(builder: (context) => AddCompanyForm());
    default:
      return MaterialPageRoute(builder: (context) => UnknownScreen());
  }
}
