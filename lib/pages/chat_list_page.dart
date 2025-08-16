import 'package:chat_app/routes/app_navigator.dart';
import 'package:chat_app/service/api_client.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
    final dio = ApiClient.instance.dio;
    final response = await dio.get(
      "/messages/conversations",
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
                final user = users[index]["user"];
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
