import 'package:chat_app/utils/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../routes/app_navigator.dart';
import '../service/api_client.dart';

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

  final _searchController = TextEditingController();
  List _searchResults = [];

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
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchRequest() async {
    try {
      final dio = ApiClient.instance.dio;

      final response = await dio.get("/friends/requests");
      if (response.statusCode == 200) {
        requests = response.data;
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
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
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
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
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteFriend(String friendId) async {
    try {
      final dio = ApiClient.instance.dio;

      final response = await dio.delete("/friends/remove/$friendId");

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa bạn thành công!")),
        );
        fetchFriends(); // cập nhật lại danh sách bạn bè
      } else {
        throw Exception("Xóa thất bại");
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xóa bạn thất bại."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchFriends(String keyword) async {
    try {
      final dio = ApiClient.instance.dio;

      final response = await dio.get("/friends/search?query=$keyword");

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = response.data;
        });
      }
    } catch (e) {
      if (!mounted) return;
      //print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xảy ra lỗi!"),
          backgroundColor: Colors.red,
        ),
      );
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể gửi lời mời"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFriendOptions(friend) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa bạn'),
                onTap: () {
                  Navigator.pop(context); // đóng bottom sheet
                  _confirmDeleteFriend(friend);
                },
              ),
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
          title: const Text("Xác nhận"),
          content: Text(
              "Bạn có chắc chắn muốn xóa '${friend["username"]}' khỏi danh sách bạn bè không?"),
          actions: [
            TextButton(
              child: const Text("Xóa", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // đóng dialog
                deleteFriend(friend["_id"]); // gọi API
              },
            ),
            TextButton(
              child: const Text("Hủy"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFriendItem(friend) {
    return ListTile(
        leading: ImageHelper.showavatar(friend["avatar"]),
        title: Text("${friend["username"]}"),
        trailing: SizedBox(
            width: 96,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    AppNavigator.goToChat(context, friend["_id"],
                        friend["username"], friend["avatar"]);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showFriendOptions(friend);
                  },
                ),
              ],
            )));
  }

  Widget _buildRequestItem(request) {
    final fromUser = request['from'];
    return ListTile(
      leading: ImageHelper.showavatar(fromUser["avatar"]),
      title: Text(fromUser["username"]),
      subtitle: const Text("Gửi lời mời kết bạn"),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              acceptRequest(request["_id"], fromUser);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              declineRequest(request["_id"], fromUser);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Danh sách"),
            Tab(text: "Lời mời"),
            Tab(text: "Thêm bạn bè"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Danh sách bạn bè
          ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) => _buildFriendItem(friends[index]),
          ),
          // Lời mời kết bạn
          ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) => _buildRequestItem(requests[index]),
          ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Tìm bạn",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (value) => _searchFriends(value),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: ImageHelper.showavatar(user["avatar"]),
                      title: Text(user["username"]),
                      trailing: ElevatedButton(
                        onPressed: () => _sendFriendRequest(user["_id"]),
                        child: const Text("Kết bạn"),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
