import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../utils/image_helper.dart';
import '../utils/time.dart';
import '../provider/post_provider.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final box = Hive.box("chat_app");
  //List<Post> _posts = [];
  final TextEditingController _contentController = TextEditingController();
  final List<File> _imageFiles = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    fetchPosts();

    _scrollController.addListener(() {
      if (!context.read<PostProvider>().isLoading &&
          _scrollController.position.extentAfter < 200) {
        fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchPosts({bool refresh = false}) async {
    try {
      await context.read<PostProvider>().fetchPosts(refresh: refresh);
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

  Future<void> fetchPostById(String postId) async {
    try {
      await context.read<PostProvider>().fetchPostById(postId);
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

      await context.read<PostProvider>().summitPost(formData);

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

  Future<void> likeunlikePost(String postId, bool isLiked) async {
    try {
      context.read<PostProvider>().toggleLike(postId, box.get("userId"));
    } catch (err) {
      if (!mounted) return;
      //print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> commentPost(String postId, String commentText) async {
    try {
      await context.read<PostProvider>().addComment(postId, commentText);
    } catch (err) {
      if (!mounted) return;
      //print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showCommentsSheet(BuildContext context, Post post) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true, // cho phép full height
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return Consumer<PostProvider>(
            builder: (context, postProvider, child) {
              final updatedPost = postProvider.getPostById(post.id);
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.thumb_up, size: 20),
                              const SizedBox(width: 6),
                              Text('${updatedPost?.likes.length}'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.comment, size: 20),
                              const SizedBox(width: 6),
                              Text('${updatedPost?.comments.length}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Body
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: updatedPost?.comments.length,
                        itemBuilder: (context, index) {
                          final comment = updatedPost?.comments[index];
                          return buildCommentItem(comment!);
                        },
                      ),
                    ),

                    // Footer nhập comment
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: MediaQuery.of(context).viewInsets.bottom +
                            12, // tránh bị che bởi bàn phím
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: "Nhập bình luận...",
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: () {
                              final text = commentController.text.trim();
                              if (text.isNotEmpty) {
                                commentPost(post.id, text);
                                commentController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
  }

  Widget buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(131, 219, 219, 219),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: ImageHelper.showavatar(comment.user.avatar),
            title: Text(comment.user.username),
            subtitle: Text(Time.formatPostTime(comment.createdAt)),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            comment.text,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>().posts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchPosts(refresh: true),
        child: ListView.builder(
          controller: _scrollController,
          itemCount:
              posts.length + 2, // +1 cho form tạo bài viết, +1 cho loading
          itemBuilder: (context, index) {
            if (index == 0) {
              // --- PHẦN TẠO BÀI VIẾT ---
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: "Bạn đang nghĩ gì",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 10),
                    if (_imageFiles.isNotEmpty) _buildSelectedImagesPreview(),
                    Row(
                      children: [
                        TextButton(
                          onPressed: pickImages,
                          child: const Icon(Icons.photo),
                        ),
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
              );
            } else if (index <= posts.length) {
              // --- HIỂN THỊ BÀI VIẾT ---
              final post = posts[index - 1];
              bool isLiked = post.likes.contains(box.get("userId"));
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: ImageHelper.showavatar(post.author.avatar),
                        title: Text(post.author.username),
                        subtitle: Text(Time.formatPostTime(post.createdAt)),
                      ),
                      const SizedBox(height: 6),
                      Text(post.content),
                      if (post.images.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...post.images.map(
                              (imageUrl) =>
                                  ImageHelper.showimage(context, imageUrl),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              likeunlikePost(post.id, isLiked);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.thumb_up,
                                      size: 20,
                                      color:
                                          isLiked ? Colors.blue : Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likes.length}',
                                    style: TextStyle(
                                      color:
                                          isLiked ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              showCommentsSheet(context, post);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.comment,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${post.comments.length}',
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // --- LOADING HOẶC HẾT DỮ LIỆU ---
              return context.read<PostProvider>().hasMore
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ))
                  : const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
