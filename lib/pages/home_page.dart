import 'package:flutter/material.dart';
import 'chat_list_page.dart';
import 'friends_page.dart';
import 'post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Danh sách các trang
  final List<Widget> _pages = const [
    ChatListPage(),
    FriendsPage(),
    PostPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền hơi xám nhẹ để làm nổi bật nội dung màu trắng bên trong các trang con
      backgroundColor: const Color(0xFFF5F7FA),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Thiết kế BottomNavigationBar nổi bật
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Đổ bóng nhẹ
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        // ClipRRect để bo tròn child bên trong (BottomNavigationBar) theo Container
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            elevation: 0,
            // Tắt bóng mặc định để dùng bóng của Container
            type: BottomNavigationBarType.fixed,
            // Cố định vị trí các nút

            // Màu sắc
            selectedItemColor: const Color(0xFF2575FC),
            // Màu xanh chủ đạo của App
            unselectedItemColor: Colors.grey.shade400,

            // Style chữ
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),

            items: const [
              // Tab 1: Tin nhắn
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble_outline_rounded),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.chat_bubble_rounded), // Icon đặc khi active
                ),
                label: 'Tin nhắn',
              ),

              // Tab 2: Bạn bè
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.people_outline_rounded),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.people_alt_rounded),
                ),
                label: 'Bạn bè',
              ),

              // Tab 3: Bài viết
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.article_outlined),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.article_rounded),
                ),
                label:
                    'Bảng tin', // Đổi tên "Bài viết" thành "Bảng tin" nghe hay hơn
              ),
            ],
          ),
        ),
      ),
    );
  }
}
