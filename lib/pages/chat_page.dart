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

  @override
  void initState() {
    super.initState();
    myUserId = box.get("userId");
    socketService.connect();
    socketService.onMessage((data) {
      if (!mounted) return;
      // Logic mới: chỉ cần kiểm tra conversationId
      if (data["conversationId"] == widget.conversation.id) {
        // Xử lý tin nhắn "đang gửi"
        final sendingMsgIndex = messages.indexWhere(
            (msg) => msg["_id"] == null && msg["content"] == data["content"]);

        if (sendingMsgIndex != -1) {
          // Tìm thấy tin nhắn đang gửi, cập nhật nó
          setState(() {
            messages[sendingMsgIndex] = data;
          });
        } else {
          // Tin nhắn mới từ người khác (hoặc ảnh của mình)
          setState(() {
            messages.insert(0, data);
          });
        }
      }
    });
    //load message history
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
    socketService.offMessage(); // nếu có
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
        "_id": null, // Đang gửi, chưa có ID
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

      // Copy sang thư mục documents để tránh lỗi cache temp
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String newPath = "${appDocDir.path}/${basename(imageFile.path)}";
      File copiedImage = await imageFile.copy(newPath);

      await uploadImageDio(copiedImage);
    }
  }

  Future<void> uploadImageDio(File imageFile) async {
    final dio = ApiClient.instance.dio;

    // Lấy mime type của file từ path
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    final typeSplit = mimeType.split('/');

    // Tạo multipart file với contentType đúng
    final multipartFile = await MultipartFile.fromFile(
      imageFile.path,
      filename: imageFile.path.split('/').last,
      contentType: MediaType(typeSplit[0], typeSplit[1]),
    );

    // Tạo form data
    final formData = FormData.fromMap({
      "image": multipartFile,
    });

    try {
      final response = await dio.post(
        "/upload",
        data: formData,
      );

      if (response.statusCode == 200) {
        final path = response.data["file"]["path"];
        socketService.sendMessage(widget.conversation.id, path, "image");
        //print("Upload thành công: $path");
      } else {
        //print("Upload thất bại: ${response.statusCode}");
        //print(response.data);
      }
    } catch (e) {
      //print("Lỗi upload ảnh: $e");
    }
  }

  Future<void> deleteMessage(BuildContext context, String messageId) async {
    try {
      final dio = ApiClient.instance.dio;
      if (messageId.isEmpty) {
        throw Exception("Đã xảy ra lỗi");
      }
      final response = await dio.delete("/messages/delete/$messageId");
      if (response.statusCode == 200) {
        setState(() {
          messages.removeWhere((msg) => msg["_id"] == messageId);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã xóa tin nhắn"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (err) {
      //print(err);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildMessageBubble(BuildContext context, dynamic message) {
    final isSelected = selectedMessageId == message["_id"];
    final sending = message["_id"] == null;
    final isMe = (sending ? message["senderId"] : message["senderId"]["_id"]) ==
        myUserId;

    return GestureDetector(
        onLongPress: () {
          setState(() {
            selectedMessageId = message["_id"];
          });
        },
        child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              children: [
                !isMe
                    ? ImageHelper.showavatar(message["senderId"]["avatar"])
                    : const Expanded(child: SizedBox.shrink()),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: sending
                        ? Colors.blueAccent.withOpacity(0.3)
                        : isSelected
                            ? Colors.redAccent.withOpacity(0.3)
                            : isMe
                                ? Colors.blueAccent
                                : Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isMe
                          ? const Radius.circular(12)
                          : const Radius.circular(0),
                      bottomRight: isMe
                          ? const Radius.circular(0)
                          : const Radius.circular(12),
                    ),
                  ),
                  child: message["type"] == "image"
                      ? ImageHelper.showimage(context, message["content"])
                      : Text(
                          message["content"],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.conversation.getDisplayName(myUserId);
    final displayAvatar = widget.conversation.getDisplayAvatar(myUserId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: Row(
          children: [
            ImageHelper.showavatar(displayAvatar),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(color: Colors.black),
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessageBubble(context, messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: pickAndSendImage,
                  icon: const Icon(Icons.image),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                )
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: selectedMessageId != null
          ? BottomAppBar(
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () async {
                      await deleteMessage(context, selectedMessageId!);
                      setState(() {
                        selectedMessageId = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Xóa tin nhắn',
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedMessageId = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.grey),
                    tooltip: 'Hủy chọn',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
