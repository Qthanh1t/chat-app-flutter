import 'package:chat_app/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/conversation_model.dart';
import '../routes/app_navigator.dart';
import '../service/api_client.dart';
import '../service/socket_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List friends = [];
  List requests = [];
  final box = Hive.box('chat_app');
  final socketService = SocketService();
  final _searchController = TextEditingController();
  List _searchResults = [];
  bool isLoading = false; // Thêm biến loading nhẹ để quản lý UI nếu cần

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchFriends();
    fetchRequest();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC GIỮ NGUYÊN ---
  Future<void> fetchFriends() async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get("/friends/list");
      if (response.statusCode == 200) {
        setState(() {
          friends = response.data;
        });
      }
    } catch (err) {
      if (!mounted) return;
      // Silent error or simple toast
    }
  }

  Future<void> _goToChatWithFriend(dynamic friend) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.post(
        "/conversations",
        data: {
          "type": "private",
          "participants": [friend["_id"]]
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final conversation = Conversation.fromJson(response.data);
        socketService.joinConversationRoom(conversation.id);
        if (mounted) AppNavigator.goToChat(context, conversation);
      } else {
        throw Exception("Lỗi tạo hội thoại");
      }
    } catch (err) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi: ${err.toString()}"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> fetchRequest() async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get("/friends/requests");
      if (response.statusCode == 200) {
        setState(() {
          requests = response.data;
        });
      }
    } catch (err) {
      // Ignore
    }
  }

  Future<void> acceptRequest(String requestId, fromUser) async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.post("/friends/accept/$requestId");
      if (response.statusCode == 200) {
        setState(() {
          fetchRequest();
          fetchFriends();
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã chấp nhận ${fromUser["username"]}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Lỗi kết nối!"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> declineRequest(String requestId, fromUser) async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.post("/friends/decline/$requestId");
      if (response.statusCode == 200) {
        setState(() {
          fetchRequest();
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã từ chối ${fromUser["username"]}'),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (err) {
      // Ignore
    }
  }

  Future<void> deleteFriend(String friendId) async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.delete("/friends/remove/$friendId");
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Đã xóa bạn thành công!"),
              behavior: SnackBarBehavior.floating),
        );
        fetchFriends();
      }
    } catch (err) {
      // Ignore
    }
  }

  Future<void> _searchFriends(String keyword) async {
    if (keyword.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get("/friends/search?query=$keyword");
      if (response.statusCode == 200) {
        setState(() {
          _searchResults = response.data;
        });
      }
    } catch (e) {
      // Ignore
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.post("/friends/request/$userId");
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Đã gửi lời mời kết bạn"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Không thể gửi lời mời"),
            backgroundColor: Colors.red),
      );
    }
  }

  // --- UI HELPERS ---

  void _showFriendOptions(friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red[50], shape: BoxShape.circle),
                  child: const Icon(Icons.person_remove, color: Colors.red),
                ),
                title: const Text('Hủy kết bạn',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteFriend(friend);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteFriend(friend) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Xác nhận xóa"),
          content: Text(
              "Bạn có chắc chắn muốn xóa '${friend["username"]}' khỏi danh sách bạn bè?"),
          actions: [
            TextButton(
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Xóa"),
              onPressed: () {
                Navigator.of(context).pop();
                deleteFriend(friend["_id"]);
              },
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFriendItem(friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
          ),
          child: ClipOval(
            child: SizedBox(
              width: 50,
              height: 50,
              child: ImageHelper.showavatar(friend["avatar"], size: 50),
            ),
          ),
        ),
        title: Text(
          "${friend["username"]}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF2575FC)),
              onPressed: () => _goToChatWithFriend(friend),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              onPressed: () => _showFriendOptions(friend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(request) {
    final fromUser = request['from'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ImageHelper.showavatar(fromUser["avatar"], size: 50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fromUser["username"],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Đã gửi lời mời kết bạn",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => acceptRequest(request["_id"], fromUser),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2575FC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text("Chấp nhận"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => declineRequest(request["_id"], fromUser),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Xóa"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2575FC), // Màu nền gradient phần trên
      appBar: AppBar(
        title: const Text("Bạn bè",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        // Để lộ nền Scaffold
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              labelColor: const Color(0xFF2575FC),
              unselectedLabelColor: Colors.white,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              // Bỏ đường kẻ mặc định
              tabs: const [
                Tab(text: "Danh sách"),
                Tab(text: "Lời mời"),
                Tab(text: "Tìm kiếm"),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Nền trắng cho phần nội dung
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              // --- TAB 1: DANH SÁCH BẠN BÈ ---
              friends.isEmpty
                  ? _buildEmptyState("Chưa có bạn bè nào", Icons.people_outline)
                  : RefreshIndicator(
                      onRefresh: fetchFriends,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 20, bottom: 80),
                        itemCount: friends.length,
                        itemBuilder: (context, index) =>
                            _buildFriendItem(friends[index]),
                      ),
                    ),

              // --- TAB 2: LỜI MỜI ---
              requests.isEmpty
                  ? _buildEmptyState("Không có lời mời mới", Icons.mail_outline)
                  : RefreshIndicator(
                      onRefresh: fetchRequest,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 20, bottom: 80),
                        itemCount: requests.length,
                        itemBuilder: (context, index) =>
                            _buildRequestItem(requests[index]),
                      ),
                    ),

              // --- TAB 3: TÌM KIẾM ---
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Nhập tên hoặc email...",
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                      onSubmitted: (value) => _searchFriends(value),
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator()),
                  Expanded(
                    child: _searchResults.isEmpty &&
                            _searchController.text.isNotEmpty &&
                            !isLoading
                        ? _buildEmptyState(
                            "Không tìm thấy người dùng", Icons.search_off)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.transparent,
                                  child: ClipOval(
                                      child: ImageHelper.showavatar(
                                          user["avatar"])),
                                ),
                                title: Text(user["username"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      _sendFriendRequest(user["_id"]),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A11CB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    elevation: 0,
                                  ),
                                  child: const Text("Kết bạn",
                                      style: TextStyle(fontSize: 12)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}
