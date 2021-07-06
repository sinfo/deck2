import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final String _deckURL =
      kIsWeb ? DotEnv().env['DECK2_URL'] : DotEnv().env['DECK2_MOBILE_URL'];
  GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  Dio dio = Dio(BaseOptions(
    baseUrl:
        kIsWeb ? DotEnv().env['DECK2_URL'] : DotEnv().env['DECK2_MOBILE_URL'],
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
    },
  ));

  Future<String> getJWT(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Response<String> response = await dio.post(
      _deckURL + '/auth/checkin',
      data: jsonEncode(<String, String>{
        'access_token': token,
      }),
    );

    if (response.data.isNotEmpty) {
      final responseJson = json.decode(response.data);
      prefs.setString("jwt", responseJson["deck_token"]);
      return responseJson["deck_token"];
    } else {
      // Handle Error
    }
  }

  Future<Member> getMe([String jwt]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Already stored member
    if (prefs.containsKey('me')) {
      return Member.fromJson(json.decode(prefs.getString("me")));
    }

    String token = jwt == null ? prefs.getString("jwt") : jwt;
    dio.options.headers[HttpHeaders.authorizationHeader] = token;
    Response<String> response = await dio.get(_deckURL + '/me');

    if (response.data.isNotEmpty) {
      final responseJson = json.decode(response.data);
      Member me = Member.fromJson(responseJson);

      prefs.setString("me", json.encode(me));
      return me;
    } else {
      // Handle error
      return null;
    }
  }

  // Used for safety
  Future<Member> login() async {
    await _googleSignIn.signInSilently();
    GoogleSignInAccount account = _googleSignIn.currentUser;
    GoogleSignInAuthentication auth = await account.authentication;
    String token = await getJWT(auth.accessToken);
    return getMe(token);
  }
}
