import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../service/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  const ChatPage(
      {super.key,
      required this.receiverId,
      required this.receiverName,
      required this.receiverAvatar});

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
  @override
  void initState() {
    super.initState();
    final myUserId = box.get("userId");
    socketService.connect();
    socketService.onMessage((data) {
      if (!mounted) return;
      if ((data["senderId"] == widget.receiverId &&
              data["receiverId"] == myUserId) ||
          (data["senderId"] == myUserId &&
              data["receiverId"] == widget.receiverId &&
              data["type"] == "image")) {
        setState(() {
          messages.add(data);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else if ((data["senderId"] == myUserId &&
          data["receiverId"] == widget.receiverId)) {
        _scrollToBottom();
      }
    });
    //load message history
    fetchMessages(currentPage).then((_) {
      // Sau khi load lần đầu xong → scroll xuống cuối
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels == 0) {
        // đang ở đầu list
        currentPage++;
        fetchMessages(currentPage);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    socketService.offMessage(); // nếu có
    super.dispose();
  }

  Future<void> fetchMessages(int page) async {
    final dio = Dio();
    final token = box.get("token");
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(
      "$baseUrl/messages/${widget.receiverId}?page=$page&limit=15",
    );

    final data = response.data["messages"].reversed.toList();
    setState(() {
      messages.insertAll(0, data); // thêm vào đầu danh sách
    });
  }

  void send() {
    final receiverId = widget.receiverId;
    final content = messageController.text;
    final myUserId = box.get("userId");
    if (content.isNotEmpty) {
      final newMessage = {
        "senderId": myUserId,
        "receiverId": receiverId,
        "content": content,
        "type": "text",
      };

      setState(() {
        messages.add(newMessage);
      });
      socketService.sendMessage(receiverId, content, "text");
      messageController.clear();
    }
  }

  void pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final token = box.get("token");

      File imageFile = File(pickedFile.path);

      // Copy sang thư mục documents để tránh lỗi cache temp
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String newPath = "${appDocDir.path}/${basename(imageFile.path)}";
      File copiedImage = await imageFile.copy(newPath);

      await uploadImageDio(copiedImage, token);
    }
  }

  Future<void> uploadImageDio(File imageFile, String token) async {
    final dio = Dio();

    // Set token vào header
    dio.options.headers["Authorization"] = "Bearer $token";

    // Lấy mime type của file từ path
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final typeSplit = mimeType.split('/');

    // Tạo multipart file với contentType đúng
    final multipartFile = await MultipartFile.fromFile(
      imageFile.path,
      filename: basename(imageFile.path),
      contentType: MediaType(typeSplit[0], typeSplit[1]),
    );

    // Tạo form data
    final formData = FormData.fromMap({
      "image": multipartFile,
    });

    try {
      final response = await dio.post(
        "$baseUrl/upload",
        data: formData,
      );

      if (response.statusCode == 200) {
        final path = response.data["file"]["path"];
        final receiverId = widget.receiverId;
        socketService.sendMessage(receiverId, path, "image");
        print("Upload thành công: $path");
      } else {
        print("Upload thất bại: ${response.statusCode}");
        print(response.data);
      }
    } catch (e) {
      print("Lỗi upload ảnh: $e");
    }
  }

  Future<void> deleteMessage(BuildContext context, String messageId) async {
    try {
      final dio = Dio();
      final token = box.get("token");
      dio.options.headers["Authorization"] = "Bearer $token";
      if (messageId.isEmpty) {
        throw Exception("Đã xảy ra lỗi");
      }
      final response = await dio.delete("$baseUrl/messages/delete/$messageId");
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
      print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildMessageBubble(BuildContext context, dynamic message) {
    final myUserId = box.get("userId");
    final isMe = message["senderId"] == myUserId;
    final isSelected = selectedMessageId == message["_id"];
    return GestureDetector(
        onLongPress: () {
          setState(() {
            selectedMessageId = message["_id"];
          });
        },
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.redAccent.withOpacity(0.3)
                  : isMe
                      ? Colors.blueAccent
                      : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft:
                    isMe ? const Radius.circular(12) : const Radius.circular(0),
                bottomRight:
                    isMe ? const Radius.circular(0) : const Radius.circular(12),
              ),
            ),
            child: message["type"] == "image"
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: message["content"],
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  )
                : Text(
                    message["content"],
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
                radius: 20,
                child: widget.receiverAvatar == ""
                    ? const Icon(Icons.person)
                    : ClipOval(
                        child: Image.network(
                          widget.receiverAvatar, // Hiển thị ảnh từ URL
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child; // Nếu ảnh đã tải xong
                            } else {
                              return const CircularProgressIndicator(); // Hiển thị loading khi ảnh đang tải
                            }
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons
                                .person); // Hiển thị icon lỗi nếu ảnh không tải được
                          }, // Đảm bảo ảnh được hiển thị đúng kích thước trong CircleAvatar
                        ),
                      )),
            const SizedBox(width: 8),
            Text(
              widget.receiverName,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
