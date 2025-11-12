// pages/create_group_page.dart
import 'package:chat_app/models/conversation_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_navigator.dart';
import 'package:chat_app/service/api_client.dart';
import 'package:chat_app/utils/image_helper.dart';
import 'package:flutter/material.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  List<User> _friends = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get("/friends/list");
      if (response.statusCode == 200) {
        final List data = response.data;
        setState(() {
          _friends = data.map<User>((json) => User.fromJson(json)).toList();
        });
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi tải danh sách bạn bè"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập tên nhóm"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn ít nhất 1 bạn"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.post(
        "/conversations",
        data: {
          "type": "group",
          "groupName": groupName,
          "participants": _selectedFriendIds.toList(),
        },
      );

      if (response.statusCode == 201) {
        final newConvo = Conversation.fromJson(response.data);
        if (!mounted) return;
        // Dùng replaceWithChat để thay thế trang này bằng trang chat
        AppNavigator.replaceWithChat(context, newConvo);
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tạo nhóm thất bại!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo nhóm mới"),
        actions: [
          // Nút tạo nhóm
          _isCreating
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : IconButton(
                  onPressed: _createGroup,
                  icon: const Icon(Icons.check),
                  tooltip: 'Tạo nhóm',
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ô nhập tên nhóm
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên nhóm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chọn thành viên:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Danh sách bạn bè để chọn
                Expanded(
                  child: ListView.builder(
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      final isSelected = _selectedFriendIds.contains(friend.id);

                      return CheckboxListTile(
                        secondary: ImageHelper.showavatar(friend.avatar),
                        title: Text(friend.username),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedFriendIds.add(friend.id);
                            } else {
                              _selectedFriendIds.remove(friend.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
