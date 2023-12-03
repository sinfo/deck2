import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/routes/company/CompanyTableNotifier.dart';
import 'package:frontend/routes/flight/FlightsNotifier.dart';
import 'package:frontend/routes/items_packages/items/ItemNotifier.dart';
import 'package:frontend/routes/items_packages/packages/PackageNotifier.dart';
import 'package:frontend/routes/members_teams/member/MemberNotifier.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/routes/session/SessionsNotifier.dart';
import 'package:frontend/routes/template/TemplatesNotifier.dart';
import 'package:frontend/routes/speaker/speakerNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/routes/members_teams/teams/TeamsNotifier.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/eventService.dart';
import 'package:provider/provider.dart';
import 'components/router.dart' as router;
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  await start();
  EventService service = EventService();
  Event latest = await service.getLatestEvent();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeNotifier>(
        create: (_) => ThemeNotifier(
          App.localStorage.getBool('darkTheme')! ? DarkTheme() : LightTheme(),
        ),
      ),
      ChangeNotifierProvider<EventNotifier>(
        create: (_) => EventNotifier(latest, latest),
      ),
      ChangeNotifierProvider<SpeakerTableNotifier>(
        create: (_) => SpeakerTableNotifier(speakers: []),
      ),
      ChangeNotifierProvider<CompanyTableNotifier>(
        create: (_) => CompanyTableNotifier(companies: []),
      ),
      ChangeNotifierProvider<MemberTableNotifier>(
        create: (_) => MemberTableNotifier(members: []),
      ),
      ChangeNotifierProvider<MeetingsNotifier>(
        create: (_) => MeetingsNotifier(meetings: []),
      ),
      ChangeNotifierProvider<FlightsNotifier>(
        create: (_) => FlightsNotifier(flights: []),
      ),
      ChangeNotifierProvider<ItemsNotifier>(
        create: (_) => ItemsNotifier(items: []),
      ),
      ChangeNotifierProvider<PackageNotifier>(
        create: (_) => PackageNotifier(packages: new Map()),
      ),
      ChangeNotifierProvider<SessionsNotifier>(
        create: (_) => SessionsNotifier(sessions: []),
      ),
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(),
      ),
      ChangeNotifierProvider<BottomNavigationBarProvider>(
        create: (_) => BottomNavigationBarProvider(),
      ),
      ChangeNotifierProvider<TeamsNotifier>(
        create: (_) => TeamsNotifier(teams: []),
      ),
      ChangeNotifierProvider<TemplatesNotifier>(
        create: (_) => TemplatesNotifier(templates: []),
      ),
    ],
    child: App(),
  ));
}

Future start() async {
  await dotenv.load(fileName: '.env');
  await App.init();
}

class App extends StatelessWidget {
  static late SharedPreferences localStorage;
  static const SIZE = 600;
  static Future init() async {
    localStorage = await SharedPreferences.getInstance();
    if (!localStorage.containsKey('darkTheme')) {
      localStorage.setBool('darkTheme', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return FutureProvider.value(
        value: Provider.of<AuthService>(context).user,
        initialData: null,
        child: MaterialApp(
            title: 'Deck',
            debugShowCheckedModeBanner: false,
            theme: themeNotifier.theme,
            onGenerateRoute: router.generateRoute));
  }
}

class BottomNavigationBarProvider with ChangeNotifier {
  int _currentIndex = 1;

  int get currentIndex => _currentIndex;
  set currentIndex(int i) {
    _currentIndex = i;
    notifyListeners();
  }
}
