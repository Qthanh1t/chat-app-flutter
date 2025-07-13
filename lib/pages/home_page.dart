import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'chat_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  List users = [];
  final box = Hive.box("chat_app");

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    final token = box.get("token");
    final response = await http.get(
      Uri.parse("$baseUrl/users/friends"),
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    setState(() {
      users = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách người dùng")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user["username"]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverId: user["_id"],
                    receiverName: user["username"],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
