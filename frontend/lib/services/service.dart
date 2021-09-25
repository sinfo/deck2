import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/main.dart';
import 'package:dio/dio.dart';

class Service {
  late Dio dio;

  Service() {
    print(dotenv.env['DECK2_MOBILE_URL']!);
    String? token = App.localStorage.getString('jwt');
    print('token= $token');
    dio = Dio(BaseOptions(
      baseUrl:
          kIsWeb ? dotenv.env['DECK2_URL']! : dotenv.env['DECK2_MOBILE_URL']!,
      headers: {
        "Content-type": 'application/json',
        "Authorization": token ?? ''
      },
    ));
  }
}
