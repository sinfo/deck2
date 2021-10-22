import 'package:flutter/material.dart';

abstract class BaseTheme {
  Color get suggested => const Color(0xFFFF9800);
  Color get contacted => const Color(0xFFFFEb3B);
  Color get accepted => const Color(0xFF2196F3);
  Color get conversations => const Color(0xFFdc3545);
  Color get rejected => const Color(0xFFF44336);
  Color get giveup => const Color(0xFF000000);

  Color get expandedColor;
  ThemeData get materialTheme;
}

class LightTheme extends BaseTheme {
  ThemeData get materialTheme {
    return ThemeData(
      primarySwatch: Colors.indigo,
      primaryColor: Colors.indigo,
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFE5E5E5),
      accentColor: Color.fromRGBO(92, 127, 242, 1),
      cardColor: Color.fromRGBO(241, 241, 241, 1),
      accentIconTheme: IconThemeData(color: Colors.white),
      dividerColor: Colors.grey,
      disabledColor: Colors.grey,
    );
  }

  Color get expandedColor => Colors.black;
}

class DarkTheme extends BaseTheme {
  ThemeData get materialTheme {
    return ThemeData(
      disabledColor: Colors.grey,
      primarySwatch: Colors.grey,
      primaryColor: Colors.black,
      brightness: Brightness.dark,
      backgroundColor: Colors.white,
      accentColor: Colors.white,
      cardColor: Color.fromRGBO(0, 0, 0, 0.6),
      accentIconTheme: IconThemeData(color: Colors.black),
      dividerColor: Colors.black12,
    );
  }

  Color get expandedColor => Colors.white;
}

class ThemeNotifier with ChangeNotifier {
  BaseTheme _themeData;

  ThemeNotifier(this._themeData);

  ThemeData get theme => _themeData.materialTheme;
  BaseTheme get fullTheme => _themeData;

  setTheme(BaseTheme themeData) async {
    _themeData = themeData;
    notifyListeners();
  }
}
