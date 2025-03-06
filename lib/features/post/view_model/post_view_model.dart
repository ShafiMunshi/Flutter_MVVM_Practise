import 'package:flutter/foundation.dart';
import 'package:mvvvm_practise/core/error_mapper.dart';
import 'package:mvvvm_practise/core/result.dart';
import 'package:mvvvm_practise/data/models/post_model/post.dart';
import 'package:mvvvm_practise/repository/post_repository.dart';

class PostViewModel extends ChangeNotifier {
  final PostRepository _repository;

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  PostViewModel(this._repository);

  void loadPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.fetchPosts();

    switch (result) {
      case Success(data: final data):
        _posts = data;
        _errorMessage = null;

      case Failure(error: final error):
        _posts = [];
        _errorMessage = ErrorMapper.toUserMessage(error);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Future<bool> _isOffline() async {
  //   try {
  //     await http.get(Uri.parse("https://www.google.com"));
  //     return false;
  //   } catch (_) {
  //     return true;
  //   }
  // }
}
