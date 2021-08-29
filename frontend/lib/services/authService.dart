import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static final String? _deckURL =
      kIsWeb ? dotenv.env['DECK2_URL'] : dotenv.env['DECK2_MOBILE_URL'];
  static final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  static final Dio dio = Dio(BaseOptions(
    baseUrl: (kIsWeb ? dotenv.env['DECK2_URL'] : dotenv.env['DECK2_MOBILE_URL'])
        as String,
    headers: {
      "Content-type": 'application/json',
    },
  ));

  static Member? _user;
  static String? _token;

  static Future<Member?> get user async {
    print('\nGetting...');
    if (_user != null) {
      print('User is not null');
      return _user;
    } else if (App.localStorage.containsKey('me')) {
      _user = Member.fromJson(json.decode(App.localStorage.getString('me')!));
      return _user;
    }
    if (_token != null) {
      bool t = await verify(_token!);
      if (t) {
        print('Token is valid');
        return getMe(_token!);
      } else {
        print('Token is not valid, returning null');
        _token = null;
        return null;
      }
    } else if (App.localStorage.containsKey('jwt')) {
      _token = App.localStorage.getString('jwt');
      bool t = await verify(_token!);
      if (t) {
        print('Token is valid');
        return getMe(_token!);
      } else {
        print('Token is not valid, returning null');
        _token = null;
        return null;
      }
    } else {
      bool isLoggedIn = _googleSignIn.currentUser != null;
      if (isLoggedIn) {
        print('Is logged in');
        GoogleSignInAccount? acc = await _googleSignIn.signInSilently();
        if (acc != null) {
          print('Signing in silently');
          GoogleSignInAuthentication auth = await acc.authentication;
          _token = await getJWT(auth.accessToken);
          return getMe(_token!);
        } else {
          print('Signing in silently failed');
          return null;
        }
      } else {
        print('Not logged in');
        return null;
      }
    }
  }

  static Future<String> getJWT(String? token) async {
    if (token != null) {
      Response<String> response = await dio.post(
        _deckURL! + '/auth/checkin',
        data: jsonEncode(<String, String>{
          'access_token': token,
        }),
      );

      try {
        final responseJson = json.decode(response.data as String);
        App.localStorage.setString("jwt", responseJson["deck_token"]);
        return responseJson["deck_token"];
      } on SocketException {
        throw DeckException('No Internet connection');
      } on HttpException {
        throw DeckException('Not found');
      } on FormatException {
        throw DeckException('Wrong format');
      }
    } else {
      return '';
    }
  }

  static Future<Member?> getMe(String token) async {
    dio.options.headers["Authorization"] = token;

    try {
      Response<String> response = await dio.get(_deckURL! + '/me');
      final responseJson = json.decode(response.data as String);
      Member me = Member.fromJson(responseJson);
      return me;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  static Future<bool> verify(String token) async {
    final url = _deckURL! + '/auth/verify/$token';
    try {
      Response<String> res = await dio.get(url);
      if (res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  // static Future<bool> isLoggedIn() async {
  //   bool isSignedIn = await _googleSignIn.isSignedIn();
  //   print('isSignedIn: $isSignedIn');
  //   return isSignedIn &&
  //       App.localStorage.containsKey('jwt') &&
  //       App.localStorage.containsKey('me');
  // }

  // static Future<bool> loginSilent() async {
  //   await _googleSignIn.signInSilently();
  //   bool isSignedIn = await _googleSignIn.isSignedIn();
  //   if (isSignedIn) {
  //     if (App.localStorage.containsKey('jwt') &&
  //         App.localStorage.containsKey('me')) {
  //       final jwt = App.localStorage.getString('jwt');
  //       return verify(jwt!);
  //     } else {
  //       GoogleSignInAccount? account = _googleSignIn.currentUser;
  //       GoogleSignInAuthentication auth = await account!.authentication;
  //       String token = await getJWT(auth.accessToken);
  //       await getMe(token);
  //       return true;
  //     }
  //   } else {
  //     return false;
  //   }
  // }

  static Future<bool> login() async {
    await _googleSignIn.disconnect();
    GoogleSignInAccount? acc = await _googleSignIn.signIn();
    if (acc != null) {
      GoogleSignInAuthentication auth = await acc.authentication;
      _token = await getJWT(auth.accessToken);
      App.localStorage.setString('jwt', _token!);
      _user = await getMe(_token!);
      App.localStorage.setString('me', json.encode(_user!.toJson()));
      return true;
    } else {
      return false;
    }
  }

  static Future signOut() async {
    try {
      _user = null;
      _token = null;
      App.localStorage.remove('me');
      App.localStorage.remove('jwt');
      await _googleSignIn.disconnect();

      bool t = _googleSignIn.currentUser != null;
      print('Signed in? $t');
    } catch (e) {
      print(e.toString());
    }
  }
}
