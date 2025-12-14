import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../service/api_client.dart';
import '../service/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../utils/image_helper.dart';
import 'package:chat_app/models/conversation_model.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  State<StatefulWidget> createState() {
    return _ChatPageState();
  }
}

class _ChatPageState extends State<ChatPage> {
  final box = Hive.box("chat_app");
  final socketService = SocketService();
  final messageController = TextEditingController();
  final List<dynamic> messages = [];
  final _scrollController = ScrollController();
  String? selectedMessageId;
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  late String myUserId;

  late final Function(dynamic) _messageListener;

  @override
  void initState() {
    super.initState();
    myUserId = box.get("userId");

    _messageListener = (data) {
      if (!mounted) return;
      if (data["conversationId"] == widget.conversation.id) {
        final sendingMsgIndex = messages.indexWhere(
            (msg) => msg["_id"] == null && msg["content"] == data["content"]);

        if (sendingMsgIndex != -1) {
          setState(() {
            messages[sendingMsgIndex] = data;
          });
        } else {
          setState(() {
            messages.insert(0, data);
          });
        }
      }
    };

    socketService.onMessage(_messageListener);
    fetchMessages(currentPage);
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 200) {
        if (hasMore && !isLoading) {
          currentPage++;
          fetchMessages(currentPage);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    socketService.offMessage(_messageListener);
    super.dispose();
  }

  Future<void> fetchMessages(int page) async {
    if (isLoading) return;
    isLoading = true;
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get(
        "/messages/${widget.conversation.id}?page=$page&limit=15",
      );
      if (response.statusCode == 200) {
        final data = response.data["messages"].toList();
        if (data.isEmpty) {
          hasMore = false;
        } else {
          setState(() {
            messages.addAll(data);
          });
        }
      }
    } finally {
      isLoading = false;
    }
  }

  void send() {
    final content = messageController.text;
    if (content.isNotEmpty) {
      final newMessage = {
        "_id": null,
        "senderId": myUserId,
        "conversationId": widget.conversation.id,
        "content": content,
        "type": "text",
      };

      setState(() {
        messages.insert(0, newMessage);
      });
      socketService.sendMessage(widget.conversation.id, content, "text");
      messageController.clear();
    }
  }

  void pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String newPath = "${appDocDir.path}/${basename(imageFile.path)}";
      File copiedImage = await imageFile.copy(newPath);

      await uploadImageDio(copiedImage);
    }
  }

  Future<void> uploadImageDio(File imageFile) async {
    final dio = ApiClient.instance.dio;
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final typeSplit = mimeType.split('/');
    final multipartFile = await MultipartFile.fromFile(
      imageFile.path,
      filename: imageFile.path.split('/').last,
      contentType: MediaType(typeSplit[0], typeSplit[1]),
    );

    final formData = FormData.fromMap({
      "image": multipartFile,
    });

    try {
      final response = await dio.post("/upload", data: formData);
      if (response.statusCode == 200) {
        final path = response.data["file"]["path"];
        socketService.sendMessage(widget.conversation.id, path, "image");
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> deleteMessage(BuildContext context, String messageId) async {
    try {
      final dio = ApiClient.instance.dio;
      if (messageId.isEmpty) throw Exception("Lỗi");
      final response = await dio.delete("/messages/delete/$messageId");
      if (response.statusCode == 200) {
        setState(() {
          messages.removeWhere((msg) => msg["_id"] == messageId);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Đã xóa tin nhắn"), backgroundColor: Colors.green),
        );
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Lỗi khi xóa!"), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI COMPONENTS ---

  Widget buildMessageBubble(BuildContext context, dynamic message) {
    final sending = message["_id"] == null; // Kiểm tra trạng thái sending
    final isSelected = sending ? false : selectedMessageId == message["_id"];
    final senderId = sending ? message["senderId"] : message["senderId"]["_id"];
    final isMe = senderId == myUserId;

    return GestureDetector(
      onLongPress: () {
        if (!sending) {
          setState(() {
            selectedMessageId = message["_id"];
          });
        }
      },
      child: Container(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.transparent,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: ClipOval(
                      child: ImageHelper.showavatar(
                          message["senderId"]["avatar"])),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // --- PHẦN THAY ĐỔI: Bọc bong bóng chat trong Opacity ---
            Opacity(
              // Nếu đang sending thì mờ đi (0.5), ngược lại hiển thị rõ (1.0)
              opacity: sending ? 0.5 : 1.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])
                        : null,
                    color: isMe ? null : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                  ),
                  child: message["type"] == "image"
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ImageHelper.showimage(
                              context, message["content"]),
                        )
                      : Text(
                          message["content"],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.conversation.getDisplayName(myUserId);
    final displayAvatar = widget.conversation.getDisplayAvatar(myUserId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: SizedBox(
                width: 36,
                height: 36,
                child: ClipOval(child: ImageHelper.showavatar(displayAvatar)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (selectedMessageId != null) {
                  setState(() => selectedMessageId = null);
                }
                FocusScope.of(context).unfocus();
              },
              child: Container(
                color: Colors.transparent,
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return buildMessageBubble(context, messages[index]);
                  },
                ),
              ),
            ),
          ),
          if (selectedMessageId == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: pickAndSendImage,
                      icon: const Icon(Icons.image,
                          color: Color(0xFF2575FC), size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: "Nhập tin nhắn...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: send,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          ),
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: selectedMessageId != null
          ? BottomAppBar(
              color: Colors.white,
              elevation: 10,
              surfaceTintColor: Colors.white,
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => selectedMessageId = null),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      label: const Text("Hủy",
                          style: TextStyle(color: Colors.black87)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await deleteMessage(context, selectedMessageId!);
                        setState(() => selectedMessageId = null);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      label: const Text("Xóa tin nhắn",
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
