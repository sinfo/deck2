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
  final String? _deckURL =
      kIsWeb ? dotenv.env['DECK2_URL'] : dotenv.env['DECK2_MOBILE_URL'];
  GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  Dio dio = Dio(BaseOptions(
    baseUrl: (kIsWeb ? dotenv.env['DECK2_URL'] : dotenv.env['DECK2_MOBILE_URL'])
        as String,
    headers: {
      "Content-type": 'application/json',
    },
  ));

  Stream<Member?> get user {
    return _googleSignIn.onCurrentUserChanged.asyncMap(_memberFromAccount);
  }

  FutureOr<Member?> _memberFromAccount(GoogleSignInAccount? acc) async {
    if (acc != null) {
      GoogleSignInAuthentication auth = await acc.authentication;
      String token = await getJWT(auth.accessToken);
      return getMe(token);
    } else {
      return null;
    }
  }

  Future<String> getJWT(String? token) async {
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

  Future<Member?> getMe(String token) async {
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

  Future<bool> verify(String token) async {
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

  Future<bool> isLoggedIn() async {
    bool isSignedIn = await _googleSignIn.isSignedIn();
    return isSignedIn &&
        App.localStorage.containsKey('jwt') &&
        App.localStorage.containsKey('me');
  }

  Future<bool> loginSilent() async {
    await _googleSignIn.signInSilently();
    bool isSignedIn = await _googleSignIn.isSignedIn();
    if (isSignedIn) {
      if (App.localStorage.containsKey('jwt') &&
          App.localStorage.containsKey('me')) {
        final jwt = App.localStorage.getString('jwt');
        return verify(jwt!);
      } else {
        GoogleSignInAccount? account = _googleSignIn.currentUser;
        GoogleSignInAuthentication auth = await account!.authentication;
        String token = await getJWT(auth.accessToken);
        await getMe(token);
        return true;
      }
    } else {
      return false;
    }
  }

  Future<bool> login() async {
    await _googleSignIn.signOut();
    GoogleSignInAccount? acc = await _googleSignIn.signIn();
    if (acc != null) {
      GoogleSignInAuthentication auth = await acc.authentication;
      String token = await getJWT(auth.accessToken);
      await getMe(token);
      return true;
    } else {
      return false;
    }
  }

  Future signOut() async {
    try {
      _googleSignIn.signOut();
    } catch (e) {
      print(e.toString());
    }
  }
}
