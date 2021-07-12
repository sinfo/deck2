import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/router.dart' as router;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  start();
  runApp(App());
}

Future start() async {
  await DotEnv().load('.env');
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
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: router.generateRoute);
  }
}
