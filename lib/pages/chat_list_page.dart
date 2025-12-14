import 'package:chat_app/routes/app_navigator.dart';
import 'package:chat_app/service/api_client.dart';
import 'package:chat_app/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/image_helper.dart';
import 'package:chat_app/models/conversation_model.dart';
import 'package:intl/intl.dart'; // Cần thêm package intl để format ngày giờ (nếu chưa có thì thêm vào pubspec.yaml)

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() {
    return _ChatListPageState();
  }
}

class _ChatListPageState extends State<ChatListPage> {
  List<Conversation> conversations = [];
  final box = Hive.box("chat_app");
  bool isLoading = false;
  late String myUserId;

  @override
  void initState() {
    super.initState();
    myUserId = box.get("userId");
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get("/conversations");
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          conversations = data
              .map<Conversation>((json) => Conversation.fromJson(json))
              .toList();
        });
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Lỗi tải tin nhắn"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2575FC),
      // Màu nền phía trên (trùng màu gradient)
      appBar: _buildCustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Nền trắng cho phần list
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: RefreshIndicator(
            onRefresh: fetchConversations,
            color: const Color(0xFF2575FC),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 20, bottom: 80),
                        // Padding bottom để tránh FAB
                        itemCount: conversations.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(height: 1, indent: 80, endIndent: 20),
                        itemBuilder: (context, index) {
                          return _buildChatItem(conversations[index]);
                        },
                      ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2575FC).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => AppNavigator.goToCreateGroup(context),
          backgroundColor: Colors.transparent,
          // Để lộ nền gradient
          elevation: 0,
          tooltip: 'Tạo nhóm mới',
          child: const Icon(Icons.group_add_rounded, size: 28),
        ),
      ),
    );
  }

  // 1. Custom AppBar với Search Bar
  PreferredSizeWidget _buildCustomAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(110),
      // Chiều cao lớn hơn bình thường
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Đoạn chat",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => AppNavigator.goToSetting(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.settings, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 2. Widget hiển thị từng item chat
  Widget _buildChatItem(Conversation convo) {
    final displayName = convo.getDisplayName(myUserId);
    final displayAvatar = convo.getDisplayAvatar(myUserId);
    final lastMsg = convo.lastMessage;

    // Logic hiển thị nội dung tin nhắn cuối
    String subtitleText = "Bắt đầu trò chuyện ngay";
    bool isImage = false;
    if (lastMsg != null) {
      if (lastMsg['type'] == 'image') {
        subtitleText = "Đã gửi một hình ảnh";
        isImage = true;
      } else {
        subtitleText = lastMsg['content'] ?? "";
      }
    }

    return InkWell(
      onTap: () => AppNavigator.goToChat(context, convo),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar với viền
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.5), width: 2),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ImageHelper.showavatar(displayAvatar, size: 50),
                ),
              ),
            ),
            const SizedBox(width: 15),

            // Nội dung text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tên người dùng
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Thời gian (Mockup)
                      Text(
                        Time.formatPostTime(convo.lastMessageAt),
                        // Bạn thay logic hiển thị giờ thật vào đây
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Tin nhắn cuối
                  Row(
                    children: [
                      if (isImage)
                        const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child:
                              Icon(Icons.image, size: 16, color: Colors.grey),
                        ),
                      Expanded(
                        child: Text(
                          subtitleText,
                          style: TextStyle(
                            fontSize: 14,
                            // Nếu là tin ảnh hoặc chưa đọc thì đậm (demo), ngược lại nhạt
                            color:
                                isImage ? Colors.black54 : Colors.grey.shade600,
                            fontWeight:
                                isImage ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Màn hình trống
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Chưa có tin nhắn nào",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Kết nối với bạn bè để bắt đầu trò chuyện!",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
