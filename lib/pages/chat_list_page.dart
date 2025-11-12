import 'package:chat_app/routes/app_navigator.dart';
import 'package:chat_app/service/api_client.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/image_helper.dart';
import 'package:chat_app/models/conversation_model.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() {
    return _ChatListPageState();
  }
}

class _ChatListPageState extends State<ChatListPage> {
  List<Conversation> conversations = [];
  final box = Hive.box("chat_app");
  bool isLoading = false;
  late String myUserId;

  @override
  void initState() {
    super.initState();
    myUserId = box.get("userId");
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get(
        "/conversations",
      );
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          conversations = data
              .map<Conversation>((json) => Conversation.fromJson(json))
              .toList();
        });
      }
    } catch (err) {
      if (!mounted) return;
      print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Điều hướng đến màn hình tạo nhóm
            AppNavigator.goToCreateGroup(context);
          },
          tooltip: 'Tạo nhóm mới',
          child: const Icon(Icons.group_add),
        ),
        body: RefreshIndicator(
          onRefresh: fetchConversations,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : conversations.isEmpty
                  ? const Center(
                      child: Text("Hãy bắt đầu một cuộc trò chuyện."))
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final convo = conversations[index];
                        final displayName = convo.getDisplayName(myUserId);
                        final displayAvatar = convo.getDisplayAvatar(myUserId);
                        final lastMsg = convo.lastMessage;

                        return ListTile(
                          leading: ImageHelper.showavatar(displayAvatar),
                          title: Text(displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            lastMsg != null ? lastMsg['content'] : '...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            // Dùng AppNavigator mới
                            AppNavigator.goToChat(context, convo);
                          },
                        );
                      },
                    ),
        ));
  }
}
