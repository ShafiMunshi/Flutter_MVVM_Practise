import 'package:mvvvm_practise/core/exceptions.dart';
import 'package:mvvvm_practise/core/result.dart';
import 'package:mvvvm_practise/data/models/post_model/post.dart';
import 'package:mvvvm_practise/data/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class PostLocalDataSource {
  final DatabaseService _dbService;
  PostLocalDataSource(this._dbService);

  Future<Result<void>> savePosts(List<Post> posts) async {
    try {
      final db = await _dbService.database;

      for (var e in posts) {
        db.insert('posts', e.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return Success(null);
    } on DatabaseException catch (e) {
      return Failure(LocalDatabaseException('Failed to save posts: $e'));
    } catch (e) {
      return Failure(
          LocalDatabaseException('Unexpected error while saving posts: $e'));
    }
  }

  Future<Result<List<Post>>> getPosts() async {
    try {
      final db = await _dbService.database;
      final result = await db.query('posts');
      final data = result.map((row) => Post.fromJson(row)).toList();

      return Success(data);
    } on DatabaseException catch (e) {
      return Failure(LocalDatabaseException('Failed to get posts: $e'));
    } catch (e) {
      return Failure(
          LocalDatabaseException('Unexpected error while getting posts: $e'));
    }
  }
}
