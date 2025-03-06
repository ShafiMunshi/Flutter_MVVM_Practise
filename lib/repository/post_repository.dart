import 'package:flutter/foundation.dart';
import 'package:mvvvm_practise/core/exceptions.dart';
import 'package:mvvvm_practise/core/result.dart';
import 'package:mvvvm_practise/data/data_sources/post/post_api_data_source.dart';
import 'package:mvvvm_practise/data/data_sources/post/post_local_data_source.dart';
import 'package:mvvvm_practise/data/models/post_model/post.dart';

class PostRepository {
  final PostApiDataSource _apiDataSource;
  final PostLocalDataSource _localDataSource;
  
  PostRepository(this._apiDataSource, this._localDataSource);

  Future<Result<List<Post>>> fetchPosts() async {
    final apiResult = await _apiDataSource.getPosts();

    switch (apiResult) {
      case Success(data: final posts):
        final saveResult = await _localDataSource.savePosts(posts);
        if (saveResult is Failure) {
          debugPrint(
              "Warning: Failed to save posts to local database ${saveResult.error.message}");
        }
        return Success(posts);
      case Failure(error: final error):
        if (error is NetworkException) {
          final localResult = await _localDataSource.getPosts();
          switch (localResult) {
            case Success(data: final posts):
              return Success(posts);
            case Failure(error: final localError):
              return Failure(localError); // Propagate database error
          }
        }

        return apiResult;
    }
  }
}
