import 'dart:convert';
import 'dart:io';
import 'package:frontend/components/deckException.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/services/service.dart';
import 'package:dio/dio.dart';

class PostService extends Service {
  final String baseUrl = '/posts';

  Future<Post?> getPost(String id) async {
    Response<String> response = await dio.get(baseUrl + '/$id');
    try {
      if (response.statusCode == 200){
        Post post = Post.fromJson(json.decode(response.data!));
        await post.loadMember();
        return post;
      } else {
        return null;
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }

  Future<Post?> updatePost(String id, String text) async {
    var body = {
      "text": text,
    };

    Response<String> response = await dio.put(baseUrl + '/$id', data: body);

    try {
      if (response.statusCode == 200){
        return Post.fromJson(json.decode(response.data!));
      } else {
        return null;
      }
    } on SocketException {
      throw DeckException('No Internet connection');
    } on HttpException {
      throw DeckException('Not found');
    } on FormatException {
      throw DeckException('Wrong format');
    }
  }
}
