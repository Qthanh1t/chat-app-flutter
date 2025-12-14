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
  final TextEditingController _contentController = TextEditingController();
  final List<File> _imageFiles = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Gọi fetch lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPosts();
    });

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
    _contentController.dispose();
    super.dispose();
  }

  // --- LOGIC GIỮ NGUYÊN ---
  Future<void> fetchPosts({bool refresh = false}) async {
    try {
      await context.read<PostProvider>().fetchPosts(refresh: refresh);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lỗi tải bài viết!"), backgroundColor: Colors.red));
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
    if (_contentController.text.trim().isEmpty && _imageFiles.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      FormData formData = FormData.fromMap({
        'content': _contentController.text.trim(),
        'images': await Future.wait(_imageFiles.map((img) async {
          final mimeType = lookupMimeType(img.path);
          if (mimeType == null || !mimeType.startsWith('image/')) return null;
          final typeSplit = mimeType.split('/');
          return await MultipartFile.fromFile(
            img.path,
            filename: img.path.split('/').last,
            contentType: MediaType(typeSplit[0], typeSplit[1]),
          );
        })),
      });

      await context.read<PostProvider>().summitPost(formData);
      _contentController.clear();
      setState(() {
        _imageFiles.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Đăng bài thành công!"),
          backgroundColor: Colors.green));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Đăng bài thất bại!"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> likeunlikePost(String postId, bool isLiked) async {
    try {
      context.read<PostProvider>().toggleLike(postId, box.get("userId"));
    } catch (err) {
      // Ignore
    }
  }

  Future<void> commentPost(String postId, String commentText) async {
    try {
      await context.read<PostProvider>().addComment(postId, commentText);
    } catch (err) {
      // Ignore
    }
  }

  // --- UI COMPONENTS ---

  void showCommentsSheet(BuildContext context, Post post) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // Header Sheet
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text("Bình luận",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(height: 1),

              // Danh sách comment
              Expanded(
                child: Consumer<PostProvider>(
                  builder: (context, postProvider, child) {
                    final updatedPost = postProvider.getPostById(post.id);
                    if (updatedPost == null || updatedPost.comments.isEmpty) {
                      return Center(
                        child: Text("Chưa có bình luận nào.",
                            style: TextStyle(color: Colors.grey[500])),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: updatedPost.comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentItem(updatedPost.comments[index]);
                      },
                    );
                  },
                ),
              ),

              // Input Comment
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        offset: const Offset(0, -2),
                        blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                          child: ImageHelper.showavatar(box.get("avatar"))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: "Viết bình luận...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Color(0xFF2575FC)),
                      onPressed: () {
                        if (commentController.text.trim().isNotEmpty) {
                          commentPost(post.id, commentController.text.trim());
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
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            child: ClipOval(child: ImageHelper.showavatar(comment.user.avatar)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.user.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(comment.text, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    Time.formatPostTime(comment.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget tạo bài viết (Status box)
  Widget _buildCreatePostCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                child:
                    ClipOval(child: ImageHelper.showavatar(box.get("avatar"))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: "Bạn đang nghĩ gì?",
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
              ),
            ],
          ),
          if (_imageFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFiles[index],
                              width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _imageFiles.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.photo_library_rounded,
                    color: Colors.green),
                label: const Text("Ảnh/Video",
                    style: TextStyle(color: Colors.black87)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2575FC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Đăng"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng bài post
  Widget _buildPostCard(Post post) {
    bool isLiked = post.likes.contains(box.get("userId"));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Bottom margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Post
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child:
                  ClipOval(child: ImageHelper.showavatar(post.author.avatar)),
            ),
            title: Text(post.author.username,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              Time.formatPostTime(post.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: const Icon(Icons.more_horiz, color: Colors.grey),
          ),

          // Content Post
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(post.content,
                  style: const TextStyle(fontSize: 15, height: 1.4)),
            ),
          const SizedBox(height: 12),

          // Images Post (Grid View giả lập)
          if (post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPostImages(post.images),
            ),

          // Stats (Like/Comment count)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Color(0xFF2575FC), shape: BoxShape.circle),
                  child:
                      const Icon(Icons.thumb_up, color: Colors.white, size: 10),
                ),
                const SizedBox(width: 6),
                Text("${post.likes.length}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                Text("${post.comments.length} bình luận",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(height: 1),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => likeunlikePost(post.id, isLiked),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                          color: isLiked
                              ? const Color(0xFF2575FC)
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Thích",
                          style: TextStyle(
                            color: isLiked
                                ? const Color(0xFF2575FC)
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => showCommentsSheet(context, post),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text("Bình luận",
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper hiển thị ảnh đẹp mắt hơn
  Widget _buildPostImages(List<dynamic> images) {
    // Nếu chỉ có 1 ảnh -> hiện Full width
    if (images.length == 1) {
      return ImageHelper.showimage(context, images[0]);
    }
    // Nếu nhiều ảnh -> Hiển thị Grid hoặc Carousel
    // Ở đây demo dạng nằm ngang scroll được để đơn giản nhưng đẹp
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 0.8, // Ảnh dọc nhẹ
              child: ImageHelper.showimage(context, images[index]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>().posts;
    final hasMore = context.read<PostProvider>().hasMore;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt
      appBar: AppBar(
        title: const Text("Bảng tin",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchPosts(refresh: true),
        color: const Color(0xFF2575FC),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: posts.length + 2, // 1 for CreatePost, 1 for Loading
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildCreatePostCard();
            } else if (index <= posts.length) {
              return _buildPostCard(posts[index - 1]);
            } else {
              return hasMore
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()))
                  : const SizedBox(height: 40); // Spacer bottom
            }
          },
        ),
      ),
    );
  }
}
