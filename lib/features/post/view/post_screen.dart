// lib/ui/post_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/post_view_model.dart';

class PostScreen extends StatefulWidget {
  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostViewModel>().loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text("Posts"),
      ),
      body: Consumer<PostViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) return Center(child: CircularProgressIndicator());
          if (vm.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(vm.errorMessage!)),
              );
            });
            if (vm.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vm.errorMessage!),
                    ElevatedButton(
                      onPressed: vm.loadPosts,
                      child: Text("Retry"),
                    ),
                  ],
                ),
              );
            }
          }
          if (vm.posts.isEmpty) {
            return Center(child: Text("No posts available."));
          }
          return ListView.builder(
            itemCount: vm.posts.length,
            itemBuilder: (_, index) {
              final post = vm.posts[index];
              return ListTile(
                title: Text(post.title),
                subtitle: Text(post.body,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<PostViewModel>().loadPosts(),
        child: Icon(Icons.refresh),
      ),
    );
  }
}
