import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box("chat_app");
    final username = box.get("username");

    return Scaffold(
      appBar: AppBar(title: Text("Xin chào, $username")),
      body: const Center(child: Text("Socket Chat App — sẵn sàng realtime!")),
    );
  }
}
