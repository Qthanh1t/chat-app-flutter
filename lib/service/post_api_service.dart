import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/post_model.dart';
import 'api_client.dart';

class PostApiService {
  final box = Hive.box("chat_app");

  Future<List<Post>> fetchPost() async {
    final dio = ApiClient.instance.dio;

    final response = await dio.get("/posts/posts");
    if (response.statusCode == 200) {
      final data = response.data as List;
      return data
          .map((post) => Post.fromJson(post as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Lỗi lấy danh sách bài viết');
    }
  }

  Future<Post> fetchPostById(String postId) async {
    final dio = ApiClient.instance.dio;

    final response = await dio.get("/posts/post/$postId");
    if (response.statusCode == 200) {
      return Post.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Lỗi lấy bài viết');
    }
  }

  Future<dynamic> submitPost(FormData formData) async {
    final dio = ApiClient.instance.dio;
    final response = await dio.post(
      "/posts/posts",
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Lỗi tạo bài viết');
    }
  }

  Future<List<dynamic>> toggleLike(String postId) async {
    final dio = ApiClient.instance.dio;

    final response = await dio.put("/posts/like/$postId");
    if (response.statusCode == 200) {
      return response.data["likes"];
    } else {
      throw Exception('Đã xảy ra lỗi');
    }
  }

  Future<List<dynamic>> commentPost(String postId, String commentText) async {
    final dio = ApiClient.instance.dio;

    final response =
        await dio.post("/posts/comment/$postId", data: {"text": commentText});
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Lỗi bình luận');
    }
  }
}
