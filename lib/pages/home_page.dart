import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../service/socket_service.dart';

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
  final List<String> messages = [];
  @override
  void initState() {
    super.initState();
    socketService.connect();
    socketService.onMessage((data) {
      setState(() {
        messages.add("${data["senderId"]}: ${data["content"]}");
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
              itemBuilder: (context, index) =>
                  ListTile(title: Text(messages[index])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
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
