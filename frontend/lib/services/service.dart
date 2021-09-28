import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/main.dart';
import 'package:dio/dio.dart';

class Service {
  late Dio dio;

  Service() {
    String? token = App.localStorage.getString('jwt');
    dio = Dio(
      BaseOptions(
        baseUrl:
            kIsWeb ? dotenv.env['DECK2_URL']! : dotenv.env['DECK2_MOBILE_URL']!,
        headers: {"Authorization": token ?? ''},
      ),
    );
    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        print('ERROR[${e.response?.statusCode}] => MESSAGE: ${e.message}');
        handler.next(e);
      },
    ));
  }
}
