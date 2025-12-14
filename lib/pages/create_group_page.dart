import 'package:chat_app/models/conversation_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_navigator.dart';
import 'package:chat_app/service/api_client.dart';
import 'package:chat_app/utils/image_helper.dart';
import 'package:flutter/material.dart';

import '../service/socket_service.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  final socketService = SocketService();
  final Set<String> _selectedFriendIds = {};
  List<User> _friends = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    // Lắng nghe thay đổi text để cập nhật trạng thái nút bấm
    _groupNameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);
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
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty || _selectedFriendIds.isEmpty) return;

    setState(() => _isCreating = true);

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
        socketService.joinConversationRoom(newConvo.id);
        AppNavigator.replaceWithChat(context, newConvo);
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Tạo nhóm thất bại!"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canCreate = _groupNameController.text.trim().isNotEmpty &&
        _selectedFriendIds.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("Tạo nhóm mới",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- Phần nhập tên nhóm ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5)),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Icon nhóm (Giả lập nút chọn ảnh)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Ô nhập tên
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên nhóm',
                      hintText: "Đặt tên cho nhóm...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // --- Tiêu đề danh sách ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Chọn thành viên",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                Text("${_selectedFriendIds.length} đã chọn",
                    style: const TextStyle(
                        color: Color(0xFF2575FC), fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // --- Danh sách bạn bè ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      final isSelected = _selectedFriendIds.contains(friend.id);

                      return _buildFriendItem(friend, isSelected);
                    },
                  ),
          ),
        ],
      ),

      // --- Nút Tạo Nhóm (Bottom Bar) ---
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 10, 20, MediaQuery.of(context).padding.bottom + 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -4),
                blurRadius: 10),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: (canCreate && !_isCreating) ? _createGroup : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2575FC),
              disabledBackgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    "Tạo nhóm (${_selectedFriendIds.length})",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendItem(User friend, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFriendIds.remove(friend.id);
          } else {
            _selectedFriendIds.add(friend.id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2575FC).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2575FC) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: ImageHelper.showavatar(friend.avatar),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle,
                          color: Color(0xFF2575FC), size: 20),
                    ),
                  )
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                friend.username,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isSelected ? const Color(0xFF2575FC) : Colors.black87,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF2575FC) : Colors.grey[400]!,
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF2575FC) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            )
          ],
        ),
      ),
    );
  }
}
