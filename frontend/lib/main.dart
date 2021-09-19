import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/eventService.dart';
import 'package:provider/provider.dart';
import 'components/router.dart' as router;
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  await start();
  EventService service = EventService();
  Event latest = await service.getLatestEvent();
  Event e;
  if (App.localStorage.containsKey('event')) {
    e = await service.getEvent(eventId: App.localStorage.getInt('event')!);
  } else {
    e = latest;
  }
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeNotifier>(
        create: (_) => ThemeNotifier(
          App.localStorage.getBool('darkTheme')! ? DarkTheme() : LightTheme(),
        ),
      ),
      ChangeNotifierProvider<EventNotifier>(
        create: (_) => EventNotifier(e, latest),
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
  static final SIZE = 600;
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
      value: AuthService.user,
      initialData: null,
      child: MaterialApp(
          title: 'Deck',
          debugShowCheckedModeBanner: false,
          theme: themeNotifier.theme,
          onGenerateRoute: router.generateRoute),
    );
  }
}
