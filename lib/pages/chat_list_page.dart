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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading = true;
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get(
        "/messages/conversations",
      );
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          users = data;
        });
      }
    } catch (err) {
      if (!mounted) return;
      //print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isLoading = false;
    }
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
        body: RefreshIndicator(
          onRefresh: fetchUsers,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : users.isEmpty
                  ? const Center(
                      child:
                          Text("Hãy kết bạn và bắt đầu một cuộc trò chuyện."))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index]["user"];
                        return ListTile(
                          leading: ImageHelper.showavatar(user["avatar"]),
                          title: Text(user["username"]),
                          onTap: () {
                            AppNavigator.goToChat(context, user["_id"],
                                user["username"], user["avatar"]);
                          },
                        );
                      },
                    ),
        ));
  }
}
