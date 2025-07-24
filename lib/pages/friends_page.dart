import 'package:chat_app/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final dio = Dio();
      final token = box.get("token");
      dio.options.headers["Authorization"] = "Bearer $token";

      final response = await dio.get("$baseUrl/friends/list");
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
      final dio = Dio();
      final token = box.get("token");
      dio.options.headers["Authorization"] = "Bearer $token";

      final response = await dio.get("$baseUrl/friends/requests");
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

  Widget _buildFriendItem(friend) {
    return ListTile(
      leading: CircleAvatar(
          radius: 20,
          child: friend["avatar"].toString() == ""
              ? const Icon(Icons.person)
              : ClipOval(
                  child: Image.network(
                    friend["avatar"].toString(), // Hiển thị ảnh từ URL
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Nếu ảnh đã tải xong
                      } else {
                        return const CircularProgressIndicator(); // Hiển thị loading khi ảnh đang tải
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons
                          .person); // Hiển thị icon lỗi nếu ảnh không tải được
                    }, // Đảm bảo ảnh được hiển thị đúng kích thước trong CircleAvatar
                  ),
                )),
      title: Text("${friend["username"]}"),
      trailing: IconButton(
        icon: const Icon(Icons.message),
        onPressed: () {
          // TODO: Mở trang chat riêng
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Mở chat với ${friend["username"]}')));
        },
      ),
    );
  }

  Widget _buildRequestItem(request) {
    final fromUser = request['from'];
    return ListTile(
      leading: CircleAvatar(
          radius: 20,
          child: fromUser["avatar"].toString() == ""
              ? const Icon(Icons.person)
              : ClipOval(
                  child: Image.network(
                    fromUser["avatar"].toString(), // Hiển thị ảnh từ URL
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Nếu ảnh đã tải xong
                      } else {
                        return const CircularProgressIndicator(); // Hiển thị loading khi ảnh đang tải
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons
                          .person); // Hiển thị icon lỗi nếu ảnh không tải được
                    }, // Đảm bảo ảnh được hiển thị đúng kích thước trong CircleAvatar
                  ),
                )),
      title: Text(fromUser["username"]),
      subtitle: const Text("Gửi lời mời kết bạn"),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              // TODO: Gọi API chấp nhận
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Đã chấp nhận ${fromUser["username"]}')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              // TODO: Gọi API từ chối
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Đã từ chối ${fromUser["username"]}')));
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
        ],
      ),
    );
  }
}
