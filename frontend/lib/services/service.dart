import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/member.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class Service {
  Dio dio;

  Service() {
    SharedPreferences.getInstance().then((value) {
      String token = value.getString('jwt');
      print(token);
      dio = Dio(BaseOptions(
        baseUrl: kIsWeb
            ? DotEnv().env['DECK2_URL']
            : DotEnv().env['DECK2_MOBILE_URL'],
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: token
        },
      ));
    });
  }
}
