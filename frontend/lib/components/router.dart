import 'package:flutter/material.dart';
import 'package:frontend/routes/HomeScreen.dart';
import 'package:frontend/routes/LoginScreen.dart';
import 'package:frontend/routes/UnknownScreen.dart';
import 'package:frontend/routes/Wrapper.dart';
import 'package:frontend/routes/company/AddCompanyForm.dart';
import 'package:frontend/routes/meeting/AddMeetingForm.dart';
import 'package:frontend/routes/members_teams/member/AddMemberForm.dart';
import 'package:frontend/routes/members_teams/member/MemberListWidget.dart';
import 'package:frontend/routes/speaker/AddSpeakerForm.dart';
import 'package:frontend/routes/members_teams/teams/AddTeamMemberForm.dart';
import 'package:frontend/routes/session/AddSessionForm.dart';

class Routes {
  static const String BaseRoute = '/';
  static const String LoginRoute = '/login';
  static const String HomeRoute = '/home';
  static const String AddCompany = '/add/company';
  static const String AddSpeaker = '/add/speaker';
  static const String ShowAllMembers = '/all/members';
  static const String AddMember = '/add/member';
  static const String AddTeamMember = '/add/teamMember';
  static const String AddMeeting = '/add/meeting';
  static const String AddSession = '/add/session';
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
      return SlideRoute(page: AddCompanyForm());
    case Routes.AddSpeaker:
      return SlideRoute(page: AddSpeakerForm());
    case Routes.ShowAllMembers:
      return MaterialPageRoute(builder: (context) => MemberListWidget());
    case Routes.AddTeamMember:
      return MaterialPageRoute(builder: (context) => AddTeamMemberForm());
    case Routes.AddMember:
      return SlideRoute(page: AddMemberForm());
    case Routes.AddMeeting:
      return SlideRoute(page: AddMeetingForm());
    case Routes.AddSession:
      return SlideRoute(page: AddSessionForm());
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

class SlideRoute extends PageRouteBuilder {
  final Widget page;
  SlideRoute({required this.page})
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
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
}
