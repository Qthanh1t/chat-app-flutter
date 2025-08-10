import 'package:chat_app/routes/app_navigator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../constants/api_constants.dart';
import '../utils/image_helper.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() {
    return _ChatListPageState();
  }
}

class _ChatListPageState extends State<ChatListPage> {
  List users = [];
  final box = Hive.box("chat_app");

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    final dio = Dio();
    final token = box.get("token");
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(
      "$baseUrl/users/friends",
    );
    final data = response.data;
    setState(() {
      users = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppNavigator.goToSetting(context);
            },
          ),
        ],
      ),
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: ImageHelper.showavatar(user["avatar"]),
                  title: Text(user["username"]),
                  onTap: () {
                    AppNavigator.goToChat(
                        context, user["_id"], user["username"], user["avatar"]);
                  },
                );
              },
            ),
    );
  }
}
