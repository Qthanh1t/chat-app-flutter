import 'package:chat_app/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:hive/hive.dart';
import '../models/post_model.dart';
import '../utils/image_helper.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final box = Hive.box("chat_app");
  List<Post> _posts = [];
  final TextEditingController _contentController = TextEditingController();
  final List<File> _imageFiles = [];
  bool _isLoading = false;
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

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _imageFiles.addAll(result.paths.map((path) => File(path!)));
      });
    }
  }

  Future<void> submitPost() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    try {
      FormData formData = FormData.fromMap({
        'content': _contentController.text.trim(),
        'images': await Future.wait(_imageFiles.map((img) async {
          final mimeType = lookupMimeType(img.path);

          // Bỏ qua file không phải ảnh
          if (mimeType == null || !mimeType.startsWith('image/')) {
            //print("❌ Bỏ qua file không phải ảnh: ${img.path}");
            return null;
          }

          final typeSplit = mimeType.split('/'); // ['image', 'jpeg']
          return await MultipartFile.fromFile(
            img.path,
            filename: img.path.split('/').last,
            contentType: MediaType(typeSplit[0], typeSplit[1]),
          );
        })),
      });

      Dio dio = Dio();
      final token = box.get('token');
      dio.options.headers["Authorization"] = "Bearer $token";
      final response = await dio.post(
        "$baseUrl/posts/posts",
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 201) {
        setState(() {
          fetchPost();
        });
      }
      _contentController.clear();
      _imageFiles.clear();
    } catch (err) {
      if (!mounted) return;
      //print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSelectedImagesPreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _imageFiles.asMap().entries.map((img) {
        int index = img.key;
        File file = img.value;
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: InkWell(
                onTap: () => setState(() {
                  _imageFiles.removeAt(index);
                }),
                child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
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
              //phan tao bai viet
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: "Bạn đang nghĩ gì",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (_imageFiles.isNotEmpty) _buildSelectedImagesPreview(),
                    Row(
                      children: [
                        TextButton(
                            onPressed: pickImages,
                            child: const Icon(Icons.photo)),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _isLoading ? null : submitPost,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Đăng bài'),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              //Phan hien thi bai viet
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ImageHelper.avatarAndName(
                                post.author.avatar, post.author.username),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(post.content),
                            if (post.images.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                ...post.images.map((imageUrl) =>
                                    ImageHelper.showimage(context, imageUrl)),
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
