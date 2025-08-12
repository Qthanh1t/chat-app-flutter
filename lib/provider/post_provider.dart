import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../service/post_api_service.dart'; // file gọi API

class PostProvider extends ChangeNotifier {
  final postApiService = PostApiService();
  List<Post> _posts = [];

  List<Post> get posts => _posts;

  // Lấy tất cả post
  Future<void> fetchPosts() async {
    final data = await postApiService.fetchPost(); // gọi API
    _posts = data;
    notifyListeners();
  }

  // Lấy một post và cập nhật
  Future<void> fetchPostById(String postId) async {
    final Post updatedPost = await postApiService.fetchPostById(postId);

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  Post? getPostById(String postId) {
    try {
      return _posts.firstWhere((p) => p.id == postId);
    } catch (e) {
      return null;
    }
  }

  // Toggle like
  void toggleLike(String postId, String userId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final newLikes = List<String>.from(post.likes);

      if (newLikes.contains(userId)) {
        newLikes.remove(userId);
      } else {
        newLikes.add(userId);
      }

      _posts[index] = post.copyWith(likes: newLikes);
      notifyListeners();

      // Gọi API cập nhật like trên server
      postApiService.toggleLike(postId);
    }
  }

  Future<void> addComment(String postId, String content) async {
    await postApiService.commentPost(postId, content); // API add comment
    await fetchPostById(postId); // Cập nhật lại post sau khi comment
  }

  Future<void> summitPost(FormData formData) async {
    await postApiService.submitPost(formData); // API add comment
    await fetchPosts(); // Cập nhật lại post sau khi comment
  }
}
