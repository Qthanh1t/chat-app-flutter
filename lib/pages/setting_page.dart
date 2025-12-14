import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../routes/app_navigator.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../service/api_client.dart';
import '../auth/auth_repository.dart';
import '../utils/image_helper.dart'; // Đảm bảo import ImageHelper

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingPageState();
  }
}

class _SettingPageState extends State<SettingPage> {
  final box = Hive.box("chat_app");

  // --- LOGIC GIỮ NGUYÊN ---
  Future<void> setAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final dio = ApiClient.instance.dio;
      File imageFile = File(pickedFile.path);

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String newPath = "${appDocDir.path}/${basename(imageFile.path)}";
      File copiedImage = await imageFile.copy(newPath);

      final mimeType = lookupMimeType(copiedImage.path) ?? 'image/jpeg';
      final typeSplit = mimeType.split('/');

      final multipartFile = await MultipartFile.fromFile(
        copiedImage.path,
        filename: basename(copiedImage.path),
        contentType: MediaType(typeSplit[0], typeSplit[1]),
      );

      final formData = FormData.fromMap({"image": multipartFile});

      try {
        final response = await dio.put("/users/setavatar", data: formData);
        if (response.statusCode == 200) {
          final path = response.data["file"]["path"];
          setState(() {
            box.put("avatar", path);
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Cập nhật ảnh đại diện thành công!"),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Lỗi upload ảnh!"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> changeUsername(BuildContext context) async {
    final nameController = TextEditingController(text: box.get("username"));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đổi tên hiển thị'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên mới',
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Tên không được để trống'
                  : null,
            ),
          ),
          actions: [
            TextButton(
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2575FC),
                  foregroundColor: Colors.white),
              child: const Text('Lưu'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newUsername = nameController.text.trim();
                  await callApiChangeUsername(context, newUsername);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> callApiChangeUsername(
      BuildContext context, String newUsername) async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio
          .put("/users/changeusername", data: {"newUsername": newUsername});

      if (response.statusCode == 200) {
        setState(() {
          box.put("username", newUsername);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đổi tên thành công!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      //print("Lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi tên không thành công!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> changePassword(BuildContext context) async {
    final passwordController1 = TextEditingController();
    final passwordController2 = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đổi mật khẩu'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController1,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => (value != null && value.length < 6)
                      ? 'Mật khẩu phải từ 6 ký tự'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController2,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nhập lại mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) =>
                      (passwordController1.text != passwordController2.text)
                          ? 'Mật khẩu không khớp!'
                          : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2575FC),
                  foregroundColor: Colors.white),
              child: const Text('Đổi mật khẩu'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newPassword = passwordController1.text.trim();
                  callApiChangePassword(context, newPassword);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> callApiChangePassword(
      BuildContext context, String newPassword) async {
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio
          .put("/users/changepassword", data: {"newPassword": newPassword});
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Đổi mật khẩu thành công!"),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lỗi đổi mật khẩu!"), backgroundColor: Colors.red));
    }
  }

  void logout(BuildContext context) async {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Đăng xuất"),
              content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                    child:
                        const Text('Hủy', style: TextStyle(color: Colors.grey)),
                    onPressed: () => Navigator.of(ctx).pop()),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    onPressed: () {
                      AuthRepository().logout();
                      AppNavigator.goToLogin(context);
                    },
                    child: const Text("Đăng xuất"))
              ],
            ));
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "Cài đặt",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5))
                            ]),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: SizedBox(
                              width: 100, height: 100,
                              child: ImageHelper.showavatar(box.get("avatar"),
                                  size: 100), // Sử dụng ImageHelper
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => setAvatar(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Color(0xFF2575FC), size: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    box.get("username") ?? "User",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Thành viên Z-Chat",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),

            // --- SETTINGS LIST ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tài khoản",
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.person_outline,
                          title: "Đổi tên hiển thị",
                          color: Colors.blueAccent,
                          onTap: () => changeUsername(context),
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildSettingTile(
                          icon: Icons.lock_outline,
                          title: "Đổi mật khẩu",
                          color: Colors.orangeAccent,
                          onTap: () => changePassword(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Hệ thống",
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.dark_mode_outlined,
                          title: "Giao diện (Sắp ra mắt)",
                          color: Colors.purpleAccent,
                          onTap: () {},
                          showArrow: false,
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildSettingTile(
                          icon: Icons.notifications_none,
                          title: "Thông báo",
                          color: Colors.green,
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 60),
                        _buildSettingTile(
                          icon: Icons.logout,
                          title: "Đăng xuất",
                          color: Colors.redAccent,
                          onTap: () => logout(context),
                          isDestructive: true,
                          showArrow: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Text(
                      "Phiên bản 1.0.0",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget để tạo dòng cài đặt
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showArrow = true,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      trailing: showArrow
          ? Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.grey[400])
          : null,
    );
  }
}
