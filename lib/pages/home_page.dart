import 'package:chat_app/routes/app_navigator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final box = Hive.box("chat_app");
              await box.delete("token");
              await box.delete("userId");
              await box.delete("username");

              AppNavigator.goToLogin(context);
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user["username"]),
            onTap: () {
              AppNavigator.goToChat(context, user["_id"], user["username"]);
            },
          );
        },
      ),
    );
  }
}
