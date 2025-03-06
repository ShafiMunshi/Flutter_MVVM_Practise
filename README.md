# Flutter MVVM Practice
Suppose you have an application where data could be comes from different sources. Also different data sources could occurs different type of error. Then how would handle that error and data in a maintainable, scalable and structural way. There MVVM comes with an appropriate solution. 

In this simple project ,we will be making an application which will first load some data from the [API source](https://jsonplaceholder.typicode.com/posts). If it successfully fetches the data, we will store that data in local database. So that, we can show that data if user has no internet. we will handle most of the type of error in [a functional way whats flutter favorite](https://docs.flutter.dev/app-architecture/design-patterns/result) using a sealed class Result type,

  First this is how our project directory structure will looks like : 
  

    lib/  
	├── core/                    # Core utilities and shared logic  
	│   ├── exceptions.dart      # Custom exception classes  
	│   ├── result.dart          # Custom Result type (Success/Failure)  
	│   └── error_mapper.dart    # Error mapping utility  
	│  
	├── data/                    # Data layer (Model)  
	│   ├── models/              # Data models for serialization  
	│   │   └── post.dart        # Post model class  
	│   ├── services/            # General data services  
	│   │   ├── api_service.dart    # Base API service  
	│   │   └── database_service.dart   # Base database service  
	│   ├── repositories/        # Feature-specific repositories  
	│   │   └── post_repository.dart # Post-specific repository  
	│   └── data_sources/        # Feature-specific data sources  
	│       ├── post/            # Post-related data sources  
	│       │   ├── post_api_data_source.dart   # Post API data source  
	│       │   └── post_local_data_source.dart # Post local data source  
	│       └── user/            # Placeholder for future features (e.g., users)  
	│  
	├── view_model/              # ViewModel layer  
	│   └── post_view_model.dart # PostViewModel  
	│  
	├── ui/                      # View layer (UI)  
	│   └── post_screen.dart     # PostScreen widget  
	│  
	└── main.dart                # App entry point  

## Understanding MVVM Architecture

MVVM divides responsibilities into three core components:

1.  **Model**: Manages data and business logic. In our app, this includes the Post model, API service, database service, and repositories/data sources. It fetches data from the API or local storage and handles errors.
2.  **View**: The UI layer, responsible for displaying data and reacting to user input. Here, post_screen.dart uses Flutter widgets to show posts or error messages.
3.  **ViewModel**: Acts as a bridge between Model and View. It processes data from the Model, manages state (e.g., loading, success, error), and notifies the View of changes. Our post_view_model.dart handles this logic.

This separation ensures the UI stays lightweight, logic remains testable, and data operations are modular.

## Handling Errors with Result Type

To manage errors gracefully, we use a sealed class Result—a Flutter favorite since Dart 3 introduced sealed classes and pattern matching. Here’s how we define it:

    // lib/core/result.dart
	sealed class Result<T> {
	  const Result();
	}

	class Success<T> extends Result<T> {
	  final T data;
	  const Success(this.data);
	}

	class Failure<T> extends Result<T> {
	  final AppException error;
	  const Failure(this.error);
	}
The Result type encapsulates two states: Success with data or Failure with an error. Paired with custom exceptions (NetworkException, ServerException, DatabaseException), it provides a unified way to handle errors across all data sources.

### Why Result is Flutter’s Favorite

-   **Type Safety**: Sealed classes enforce handling all cases (Success or Failure), preventing unhandled errors at runtime.
-   **Pattern Matching**: Dart’s switch makes it concise and readable: switch (result) { case Success(data): ... case Failure(error): ... }.
-   **No Dependencies**: Built into Dart, it’s lightweight compared to libraries like dartz.
-   **Reactive Fit**: Perfect for Flutter’s state-driven UI, integrating seamlessly with ChangeNotifier or other state management tools.

## Core Components

### Custom Exceptions
We define errors in exceptions.dart:

    // lib/core/exceptions.dart
	abstract class AppException implements Exception {
	  final String message;
	  AppException(this.message);
	}

	class NetworkException extends AppException {
	  NetworkException() : super("No internet connection.");
	}

	class ServerException extends AppException {
	  ServerException(String details) : super("Server error: $details");
	}

	class DatabaseException extends AppException {
	  DatabaseException(String details) : super("Database error: $details");
	}

These allow us to categorize and handle errors precisely.


## Data Layer (Model)

### API Service

The ApiService is secured using a .env file for baseUrl and apiToken:

    // lib/data/services/api_service.dart
	import 'package:http/http.dart' as http;

	class ApiService {
	  final String baseUrl;
	  final String apiToken;
	  final http.Client client;

	  ApiService({
	    required this.baseUrl,
	    required this.apiToken,
	    http.Client? client,
	  }) : client = client ?? http.Client();

	  Future<http.Response> get(String endpoint) async {
	    final uri = Uri.parse('$baseUrl$endpoint');
	    return await client.get(uri, headers: {
	      'Authorization': 'Bearer $apiToken',
	      'Content-Type': 'application/json',
	    });
	  }
	}

### Database Service

The DatabaseService sets up SQLite:

    // lib/data/services/database_service.dart
	import 'package:sqflite/sqflite.dart';
	import 'package:path_provider/path_provider.dart';
	import 'package:path/path.dart';

	class DatabaseService {
	  static Database? _database;

	  Future<Database> get database async {
	    if (_database != null) return _database!;
	    _database = await _initDatabase();
	    return _database!;
	  }

	  Future<Database> _initDatabase() async {
	    final directory = await getApplicationDocumentsDirectory();
	    final path = join(directory.path, 'app_database.db');
	    return await openDatabase(path, version: 1, onCreate: (db, version) async {
	      await db.execute('''
	        CREATE TABLE posts (
	          id INTEGER PRIMARY KEY,
	          userId INTEGER NOT NULL,
	          title TEXT NOT NULL,
	          body TEXT NOT NULL
	        )
	      ''');
	    });
	  }
	}



### Data Sources

-   **Post API Data Source**:

    // lib/data/data_sources/post/post_api_data_source.dart
		import 'dart:convert';
		import 'package:http/http.dart' as http;
		import '../../models/post.dart';
		import '../../services/api_service.dart';
		import '../../core/exceptions.dart';
		import '../../core/result.dart';

		class PostApiDataSource {
		  final ApiService _apiService;

		  PostApiDataSource(this._apiService);

		  Future<Result<List<Post>>> fetchPosts() async {
		    try {
		      final response = await _apiService.get('/posts');
		      if (response.statusCode == 200) {
		        final data = jsonDecode(response.body) as List;
		        return Success(Post.fromJsonList(data));
		      } else if (response.statusCode >= 500) {
		        return Failure(ServerException("Status ${response.statusCode}"));
		      } else if (response.statusCode == 401) {
		        return Failure(AppException("Unauthorized: Invalid token"));
		      }
		      return Failure(AppException("Unexpected response: ${response.statusCode}"));
		    } on http.ClientException {
		      return Failure(NetworkException());
		    } catch (e) {
		      return Failure(AppException("Unknown error: $e"));
		    }
		  }
		}


-   **Post Local Data Source**:

    // lib/data/data_sources/post/post_local_data_source.dart
		import 'package:sqflite/sqflite.dart';
		import '../../models/post.dart';
		import '../../services/database_service.dart';
		import '../../core/exceptions.dart';
		import '../../core/result.dart';

		class PostLocalDataSource {
		  final DatabaseService _dbService;

		  PostLocalDataSource(this._dbService);

		  Future<Result<void>> savePosts(List<Post> posts) async {
		    try {
		      final db = await _dbService.database;
		      await db.transaction((txn) async {
		        await txn.delete('posts');
		        for (final post in posts) {
		          await txn.insert('posts', post.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
		        }
		      });
		      return Success(null);
		    } on DatabaseException catch (e) {
		      return Failure(DatabaseException("Failed to save posts: ${e.message}"));
		    } on Exception catch (e) {
		      return Failure(DatabaseException("Unexpected error while saving posts: $e"));
		    }
		  }

		  Future<Result<List<Post>>> getPosts() async {
		    try {
		      final db = await _dbService.database;
		      final result = await db.query('posts');
		      final posts = result.map((row) => Post(
		        userId: row['userId'] as int,
		        id: row['id'] as int,
		        title: row['title'] as String,
		        body: row['body'] as String,
		      )).toList();
		      return Success(posts);
		    } on DatabaseException catch (e) {
		      return Failure(DatabaseException("Failed to fetch posts: ${e.message}"));
		    } on Exception catch (e) {
		      return Failure(DatabaseException("Unexpected error while fetching posts: $e"));
		    }
		  }
		}

### Repository

The PostRepository combines data sources:

    // lib/data/repositories/post_repository.dart
    
	import '../data_sources/post/post_api_data_source.dart';
	import '../data_sources/post/post_local_data_source.dart';
	import '../../core/result.dart';
	import '../../models/post.dart';

	class PostRepository {
	  final PostApiDataSource _apiDataSource;
	  final PostLocalDataSource _localDataSource;

	  PostRepository(this._apiDataSource, this._localDataSource);

	  Future<Result<List<Post>>> fetchPosts() async {
	    final apiResult = await _apiDataSource.fetchPosts();
	    switch (apiResult) {
	      case Success(data: final posts):
	        final saveResult = await _localDataSource.savePosts(posts);
	        if (saveResult is Failure) {
	          print("Warning: Failed to cache posts - ${saveResult.error.message}");
	        }
	        return Success(posts);
	      case Failure(error: final error):
	        if (error is NetworkException) {
	          final localResult = await _localDataSource.getPosts();
	          switch (localResult) {
	            case Success(data: final posts) when posts.isNotEmpty:
	              return Success(posts);
	            case Success(data: final posts) when posts.isEmpty:
	              return Failure(NetworkException());
	            case Failure(error: final localError):
	              return Failure(localError);
	          }
	        }
	        return apiResult;
	    }
	  }
	}

# Post-Viewmodel
This contains the business logic for communicating with the UI .

    import  'package:flutter/foundation.dart';
	import  'package:mvvvm_practise/core/error_mapper.dart';
	import  'package:mvvvm_practise/core/result.dart';
	import  'package:mvvvm_practise/data/models/post_model/post.dart';
	import  'package:mvvvm_practise/repository/post_repository.dart';

	  
	class  PostViewModel  extends  ChangeNotifier {
	final  PostRepository  _repository;

	List<Post> _posts  = [];
	List<Post> get  posts => _posts;

	String?  _errorMessage;
	String?  get  errorMessage => _errorMessage;

	bool  _isLoading  =  false;
	bool  get  isLoading => _isLoading;

	PostViewModel(this._repository);

	void  loadPosts() async {
	_isLoading  =  true;
	_errorMessage  =  null;
	notifyListeners();
	final  result  =  await  _repository.fetchPosts();
	
	switch (result) {
	case  Success(data:  final  data):
	_posts  =  data;
	_errorMessage  =  null;
	
	case  Failure(error:  final  error):
	_posts  = [];
	_errorMessage  =  ErrorMapper.toUserMessage(error);
	}

	_isLoading  =  false;
	notifyListeners();
	}
	}

## Conclusion

Using MVVM with a sealed class Result in Flutter provides a structured, scalable way to handle data and errors. It leverages Dart’s modern features for type safety and readability, making it a favorite among Flutter developers. Whether you’re fetching from an API, caching locally, or managing offline scenarios, this approach keeps your codebase clean and your users happy. Try it in your next project!
