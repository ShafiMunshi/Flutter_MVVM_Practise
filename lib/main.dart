import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mvvvm_practise/data/data_sources/post/post_api_data_source.dart';
import 'package:mvvvm_practise/data/data_sources/post/post_local_data_source.dart';
import 'package:mvvvm_practise/data/services/api_services.dart';
import 'package:mvvvm_practise/data/services/database_service.dart';
import 'package:mvvvm_practise/features/post/view/post_screen.dart';
import 'package:mvvvm_practise/features/post/view_model/post_view_model.dart';
import 'package:mvvvm_practise/repository/post_repository.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // await dotenv.load(fileName: ".env"); // Load .env file
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => PostViewModel(
                  PostRepository(
                    PostApiDataSource(
                      ApiServices(),
                    ),
                    PostLocalDataSource(DatabaseService()),
                  ),
                ))
      ],
      child: MaterialApp(
        title: 'Flutter MVVM Practice',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: PostScreen(),
      ),
    );
  }
}
