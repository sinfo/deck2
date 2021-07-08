import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/main.dart';
import 'package:dio/dio.dart';

class Service {
  Dio dio;

  Service() {
    String token = App.localStorage.getString('jwt');
    dio = Dio(BaseOptions(
      baseUrl:
          kIsWeb ? DotEnv().env['DECK2_URL'] : DotEnv().env['DECK2_MOBILE_URL'],
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: token
      },
    ));
  }
}
