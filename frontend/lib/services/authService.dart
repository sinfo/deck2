import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum Role {
  UNKNOWN,
  MEMBER,
  TEAMLEADER,
  COORDINATOR,
  ADMIN,
}

class AuthService extends ChangeNotifier {
  final String? _deckURL =
      kIsWeb ? dotenv.env['DECK2_URL'] : dotenv.env['DECK2_MOBILE_URL'];
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: ['email'], hostedDomain: "sinfo.org");
  final Dio _dio = Dio(BaseOptions(
    baseUrl: (kIsWeb ? dotenv.env['DECK2_URL'] : dotenv.env['DECK2_MOBILE_URL'])
        as String,
  ));

  Member? _user;
  String? _token;
  Role? _role;

  Future<Role?> get role async {
    if (_role != null) {
      return _role;
    }

    Member? me = await user;
    if (_token == null) {
      if (App.localStorage.containsKey('jwt')) {
        _token = App.localStorage.getString('jwt');
      } else {
        bool isLoggedIn = _googleSignIn.currentUser != null;
        if (isLoggedIn) {
          GoogleSignInAccount? acc = await _googleSignIn.signInSilently();
          if (acc != null) {
            GoogleSignInAuthentication auth = await acc.authentication;
            _token = await getJWT(auth.accessToken);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
    }
    bool t = await verify(_token!);
    if (t) {
      Member? me;
      if (_user == null) {
        _user = await getMe(_token!);
      }
      me = _user;

      try {
        _dio.options.headers["Authorization"] = _token;

        Response<String> response =
            await _dio.get(_deckURL! + '/members/${me!.id}/role');
        final responseJson = json.decode(response.data as String);
        _role = convert(responseJson['role']);
        return _role;
      } on SocketException {
        throw DeckException('No Internet connection');
      } on HttpException {
        throw DeckException('Not found');
      } on FormatException {
        throw DeckException('Wrong format');
      }
    }
  }

  Role convert(String s) {
    switch (s) {
      case 'ADMIN':
        return Role.ADMIN;
      case 'COORDINATOR':
        return Role.COORDINATOR;
      case 'TEAMLEADER':
        return Role.TEAMLEADER;
      case 'MEMBER':
        return Role.MEMBER;
      default:
        return Role.UNKNOWN;
    }
  }

  Future<Member?> get user async {
    if (_user != null) {
      return _user;
    }
    if (_token != null) {
      bool t = await verify(_token!);
      if (t) {
        return getMe(_token!);
      } else {
        _token = null;
        return null;
      }
    } else if (App.localStorage.containsKey('jwt')) {
      _token = App.localStorage.getString('jwt');
      bool t = await verify(_token!);
      if (t) {
        return getMe(_token!);
      } else {
        _token = null;
        return null;
      }
    } else {
      bool isLoggedIn = _googleSignIn.currentUser != null;
      if (isLoggedIn) {
        GoogleSignInAccount? acc = await _googleSignIn.signInSilently();
        if (acc != null) {
          GoogleSignInAuthentication auth = await acc.authentication;
          _token = await getJWT(auth.accessToken);
          return getMe(_token!);
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
  }

  Future<String> getJWT(String? token) async {
    if (token != null) {
      Response<String> response = await _dio.post(
        _deckURL! + '/auth/checkin',
        data: jsonEncode(<String, String>{
          'access_token': token,
        }),
      );

      try {
        final responseJson = json.decode(response.data as String);
        App.localStorage.setString("jwt", responseJson["deck_token"]);
        _token = responseJson["deck_token"];
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
    _dio.options.headers["Authorization"] = token;

    try {
      Response<String> response = await _dio.get(_deckURL! + '/me');
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
      Response<String> res = await _dio.get(url);
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

  Future<bool> login() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.disconnect();
    }
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

  Future signOut() async {
    try {
      _user = null;
      _token = null;
      App.localStorage.remove('me');
      App.localStorage.remove('jwt');
      await _googleSignIn.disconnect();
    } catch (e) {
      print(e.toString());
    }
  }
}
