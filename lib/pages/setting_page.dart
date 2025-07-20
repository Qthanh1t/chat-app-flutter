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
import '../constants/api_constants.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  @override
  State<StatefulWidget> createState() {
    return _SettingPageState();
  }
}

class _SettingPageState extends State<SettingPage> {
  final box = Hive.box("chat_app");

  Future<void> setAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final token = box.get("token");
      final dio = Dio();
      File imageFile = File(pickedFile.path);

      // Copy sang thư mục documents để tránh lỗi cache temp
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String newPath = "${appDocDir.path}/${basename(imageFile.path)}";
      File copiedImage = await imageFile.copy(newPath);

      // Set token vào header
      dio.options.headers["Authorization"] = "Bearer $token";

      // Lấy mime type của file từ path
      final mimeType = lookupMimeType(copiedImage.path) ?? 'image/jpeg';
      final typeSplit = mimeType.split('/');

      // Tạo multipart file với contentType đúng
      final multipartFile = await MultipartFile.fromFile(
        copiedImage.path,
        filename: basename(copiedImage.path),
        contentType: MediaType(typeSplit[0], typeSplit[1]),
      );

      // Tạo form data
      final formData = FormData.fromMap({
        "image": multipartFile,
      });

      try {
        final response = await dio.put(
          "$baseUrl/users/setavatar",
          data: formData,
        );

        if (response.statusCode == 200) {
          final path = response.data["file"]["path"];
          setState(() {
            box.put("avatar", path);
          });

          print("Upload thành công");
        } else {
          print("Upload thất bại: ${response.statusCode}");
          print(response.data);
        }
      } catch (e) {
        print("Lỗi upload ảnh: $e");
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
          title: const Text('Đổi tên'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên người dùng',
                      icon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tên không được để trống';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
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
      final token = box.get("token");
      final dio = Dio();
      dio.options.headers["Authorization"] = "Bearer $token";
      final response = await dio.put("$baseUrl/users/changeusername",
          data: {"newUsername": newUsername});

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
      print("Lỗi: $e");
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
          title: const Text('Cập nhật thông tin'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passwordController1,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      icon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if ((value != null &&
                              value.isNotEmpty &&
                              value.length < 6) ||
                          (value != null && value.isEmpty)) {
                        return 'Mật khẩu phải từ 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController2,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      icon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (passwordController1.text !=
                          passwordController2.text) {
                        return 'Hãy nhập lại chính xác mật khẩu!';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Lưu'),
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
      final token = box.get("token");
      final dio = Dio();
      dio.options.headers["Authorization"] = "Bearer $token";
      final response = await dio.put("$baseUrl/users/changepassword",
          data: {"newPassword": newPassword});

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đổi mật khẩu thành công!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu không thành công!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void logout(BuildContext context) async {
    final box = Hive.box("chat_app");
    await box.delete("token");
    await box.delete("userId");
    await box.delete("username");
    await box.delete("avatar");
    AppNavigator.goToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Cài đặt')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                      radius: 30,
                      child: box.get("avatar") == ""
                          ? const Icon(Icons.person)
                          : ClipOval(
                              child: Image.network(
                                box.get("avatar"), // Hiển thị ảnh từ URL
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
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
                  const SizedBox(width: 16),
                  Text(
                    box.get("username"),
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ],
              ),
              const Divider(
                height: 32,
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Đổi ảnh đại diện"),
                onTap: setAvatar,
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Đổi tên"),
                onTap: () => changeUsername(context),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Đổi mật khẩu"),
                onTap: () => changePassword(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Đăng xuất"),
                onTap: () => logout(context),
              ),
            ],
          ),
        ));
  }
}
