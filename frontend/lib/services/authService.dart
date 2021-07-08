import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final String? _deckURL =
      kIsWeb ? DotEnv().env['DECK2_URL'] : DotEnv().env['DECK2_MOBILE_URL'];
  GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  Dio dio = Dio(BaseOptions(
    baseUrl: (kIsWeb
        ? DotEnv().env['DECK2_URL']
        : DotEnv().env['DECK2_MOBILE_URL']) as String,
    headers: {
      "Content-type": 'application/json',
    },
  ));

  Future<String> getJWT(String? token) async {
    if (token != null) {
      Response<String> response = await dio.post(
        _deckURL! + '/auth/checkin',
        data: jsonEncode(<String, String>{
          'access_token': token,
        }),
      );

      if (response.data!.isNotEmpty) {
        final responseJson = json.decode(response.data as String);
        App.localStorage.setString("jwt", responseJson["deck_token"]);
        return responseJson["deck_token"];
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

  Future<Member?> getMe([String? jwt]) async {
    // Already stored member
    if (App.localStorage.containsKey('me')) {
      print('here1');
      print(App.localStorage.getString("me"));
      return Member.fromJson(json.decode(App.localStorage.getString("me")));
    }

    print('here');

    String token = jwt == null ? App.localStorage.getString("jwt") : jwt;
    dio.options.headers["Authorization"] = token;
    Response<String> response = await dio.get(_deckURL! + '/me');

    if (response.data!.isNotEmpty) {
      final responseJson = json.decode(response.data as String);
      Member me = Member.fromJson(responseJson);

      App.localStorage.setString("me", json.encode(me));
      return me;
    } else {
      // Handle error
      return null;
    }
  }

  // Used for safety
  Future<Member?> login() async {
    await _googleSignIn.signInSilently();
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    GoogleSignInAuthentication auth = await account!.authentication;
    String token = await getJWT(auth.accessToken);
    print('loggin in...');
    return getMe(token);
  }
}
