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

  String? _token;
  Member? _user;
  Role? _role;

  Future<bool> login() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.disconnect();
    }

    GoogleSignInAccount? acc = await _googleSignIn.signIn();
    if (acc != null) {
      GoogleSignInAuthentication auth = await acc.authentication;
      if (auth.accessToken == null) { return false; }
      // Generate JWT from Google access token
      await generateJWT(auth.accessToken!);
      return true;
    }

    return false;
  }

  Future signOut() async {
    try {
      _user = null;
      _token = null;
      _dio.options.headers["Authorization"] = null;
      App.localStorage.remove('jwt');
      await _googleSignIn.disconnect();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<String?> get token async {
    if (_token != null) {
      return _token;
    }

    if (App.localStorage.containsKey('jwt')) {
      // Log
      _token = App.localStorage.getString('jwt');
      // Verify token, if valid, exception is thrown
      try {
        if (await verifyToken(_token!)) {
          _dio.options.headers["Authorization"] = _token;

          notifyListeners();
          return _token;
        }
      } catch (e) {}

      // If token is invalid, sign out
      await signOut();
    }

    return null;
  }

  Future<Member?> get user async {
    if (_user != null) {
      return _user;
    }

    String? token = await this.token;
    if (token != null) {
      _user = await getMe(token);
      notifyListeners();
      return _user;
    }

    return null;
  }

  Future<Role?> get role async {
    if (_role != null) {
      return _role;
    }

    Member? me = await user;
    if (me != null) {
      _role = await getRole(me.id);

      notifyListeners();
      return _role;
    }

    return null;
  }

  Role convertStringToRole(String s) {
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

  Future<String?> generateJWT(String accessToken) async {
    try {
      Response<String> response = await _dio.post(
        _deckURL! + '/auth/checkin',
        data: jsonEncode(<String, String>{
          'access_token': accessToken,
        }),
      );

      final responseJson = json.decode(response.data as String);
      App.localStorage.setString("jwt", responseJson["deck_token"]);
      return token;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Role?> getRole(String userId) async {
      try {
        Response<String> response =
            await _dio.get(_deckURL! + '/members/$userId/role');
        final responseJson = json.decode(response.data as String);
        _role = convertStringToRole(responseJson['role']);
        return _role;
      } on SocketException {
        throw DeckException('No Internet connection');
      } on HttpException {
        throw DeckException('Not found');
      } on FormatException {
        throw DeckException('Wrong format');
      }
  }

  Future<Member?> getMe(String token) async {
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

  Future<bool> verifyToken(String token) async {
    try {
      Response<String> res = await _dio.get(_deckURL! + '/auth/verify/$token');
      return res.statusCode == 200;
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

}
