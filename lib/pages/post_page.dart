import 'package:chat_app/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/post_model.dart';
import '../utils/avatar_name.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final box = Hive.box("chat_app");
  List<Post> _posts = [];
  @override
  void initState() {
    super.initState();
    fetchPost();
  }

  Future<void> fetchPost() async {
    try {
      final dio = Dio();
      final token = box.get("token");
      dio.options.headers["Authorization"] = "Bearer $token";

      final response = await dio.get("$baseUrl/posts/posts");
      if (response.statusCode == 200) {
        final data = response.data as List;
        setState(() {
          _posts = data
              .map((post) => Post.fromJson(post as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPost,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              //TODO phan tao bai viet

              //Phan hien thi bai viet
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AvatarName.avatarAndName(
                                post.author.avatar, post.author.username),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(post.content),
                            if (post.images.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                ...post.images.map((imageUrl) =>
                                    AvatarName.showimage(imageUrl)),
                              ]),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.thumb_up, size: 20),
                                const SizedBox(width: 4),
                                Text('${post.likes.length}'),
                                const SizedBox(width: 16),
                                const Icon(Icons.comment, size: 20),
                                const SizedBox(width: 4),
                                Text('${post.comments.length}'),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  })
            ],
          ),
        ),
      ),
    );
  }
}
