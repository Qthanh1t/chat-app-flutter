import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../service/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage(
      {super.key, required this.receiverId, required this.receiverName});

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
  int currentPage = 1;
  @override
  void initState() {
    super.initState();
    final myUserId = box.get("userId");
    socketService.connect();
    socketService.onMessage((data) {
      if (!mounted) return;
      if ((data["senderId"] == widget.receiverId &&
          data["receiverId"] == myUserId)) {
        setState(() {
          messages.add(data);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
      if ((data["senderId"] == myUserId &&
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
    final token = box.get("token");
    final response = await http.get(
      Uri.parse(
          "http://10.0.2.2:5000/api/messages/${widget.receiverId}?page=$page&limit=15"),
      headers: {"Authorization": "Bearer $token"},
    );

    final responseJson = jsonDecode(response.body);
    final data = responseJson["messages"].reversed.toList();
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
      socketService.sendMessage(receiverId, content);
      messageController.clear();
    }
  }

  void pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final receiverId = widget.receiverId;
      socketService.sendImage(receiverId, base64Image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat với ${widget.receiverName}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: message["type"] == "image"
                      ? Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Thêm dòng này
                          children: [
                            Text(
                              "${message["senderId"]}:",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                message["content"],
                                width: double.infinity, // hoặc để null
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${message["senderId"]}: ${message["content"]}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                );
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
                  child: TextField(
                    controller: messageController,
                    decoration:
                        const InputDecoration(hintText: "Nhập tin nhắn..."),
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
    );
  }
}
