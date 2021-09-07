import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/components/deckTheme.dart';
import 'package:frontend/services/authService.dart';
import 'package:provider/provider.dart';
import 'components/router.dart' as router;
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  await start();
  runApp(ChangeNotifierProvider<ThemeNotifier>(
    create: (_) => ThemeNotifier(
      App.localStorage.getBool('darkTheme')! ? DarkTheme() : LightTheme(),
    ),
    child: App(),
  ));
}

Future start() async {
  await dotenv.load(fileName: '.env');
  await App.init();
}

class App extends StatelessWidget {
  static late SharedPreferences localStorage;
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
