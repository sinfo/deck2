import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/router.dart' as router;
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  await start();
  runApp(App());
}

Future start() async {
  await dotenv.load(fileName: '.env');
  await App.init();
}

class App extends StatelessWidget {
  static late SharedPreferences localStorage;
  static Future init() async {
    localStorage = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Deck',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          accentColor: Color.fromRGBO(92, 127, 242, 1),
          cardColor: Color.fromRGBO(241, 241, 241, 1),

          visualDensity: VisualDensity.adaptivePlatformDensity,
          dividerTheme: DividerThemeData(
            space: 20,
            thickness: 2,
            color: Color.fromRGBO(211, 211, 211, 1),
            endIndent: 18,
          )
        ),
        onGenerateRoute: router.generateRoute);
  }
}
