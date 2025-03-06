import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mvvvm_practise/core/exceptions.dart';
import 'package:mvvvm_practise/core/result.dart';
import 'package:mvvvm_practise/data/models/post_model/post.dart';
import 'package:mvvvm_practise/data/services/api_services.dart';

class PostApiDataSource {
  final ApiServices _apiServices;

  PostApiDataSource(this._apiServices);

  Future<Result<List<Post>>> getPosts() async {
    try {
      final response = await _apiServices.get('/posts');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return Success(Post.fromJsonList(data));
      } else if (response.statusCode >= 500) {
        return Failure(ServerException("Status ${response.statusCode}"));
      }
      return Failure(UnknownException("Unexpected response: ${response.body}"));
    } on http.ClientException {
      return Failure(NetworkException());
    } catch (e) {
      return Failure(UnknownException(e.toString()));
    }
  }
}
