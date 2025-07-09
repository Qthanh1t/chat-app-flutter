import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../service/socket_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box("chat_app");
  final socketService = SocketService();
  final messageController = TextEditingController();
  final List<dynamic> messages = [];
  @override
  void initState() {
    super.initState();
    socketService.connect();
    socketService.onMessage((data) {
      setState(() {
        messages.add(data);
      });
    });
  }

  void send() {
    final receiverId = "6865097aaf8e19212cfdf614"; // test hardcode
    final content = messageController.text;
    if (content.isNotEmpty) {
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
      final receiverId = "6865097aaf8e19212cfdf614"; // test hardcode
      socketService.sendImage(receiverId, base64Image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = box.get("username");

    return Scaffold(
      appBar: AppBar(title: Text("Xin chào, $username")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
