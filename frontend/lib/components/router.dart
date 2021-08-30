import 'package:flutter/material.dart';
import 'package:frontend/routes/HomeScreen.dart';
import 'package:frontend/routes/LoginScreen.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/routes/Wrapper.dart';
import 'package:frontend/routes/company/AddCompanyForm.dart';

class Routes {
  static const String BaseRoute = '/';
  static const String LoginRoute = '/login';
  static const String HomeRoute = '/home';
  static const String AddCompany = '/add/company';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.BaseRoute:
      return MaterialPageRoute(builder: (context) => WrapperPage());
    case Routes.LoginRoute:
      return FadeRoute(page: LoginScreen());
    case Routes.HomeRoute:
      return FadeRoute(page: HomeScreen());
    case Routes.AddCompany:
      return MaterialPageRoute(builder: (context) => AddCompanyForm());
    default:
      return MaterialPageRoute(builder: (context) => UnknownScreen());
  }
}

class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
}
