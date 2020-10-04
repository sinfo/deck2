import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/member.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String _deckURL = DotEnv().env['DECK2_URL'];

  Future<void> getJWT(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(
      _deckURL + '/auth/checkin',
      body: jsonEncode(<String, String>{
        'access_token': token,
      }),
    );

    if (response.body.isNotEmpty) {
      final responseJson = json.decode(response.body);
      prefs.setString("jwt", responseJson["deck_token"]);
    } else {
      // Handle Error
    }
  }

  Future<Member> getMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("jwt");
    final response = await http.get(
      _deckURL + '/me',
      headers: {HttpHeaders.authorizationHeader: token},
    );

    final responseJson = json.decode(response.body);
    print(responseJson);
    Member me = Member.fromJson(responseJson);

    prefs.setString("me", json.encode(me));
  }
}
