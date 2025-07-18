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

  void setAvatar() async {
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
        final response = await dio.post(
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

  void changeUsername() {}

  void changePassword() {}

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
                onTap: changeUsername,
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Đổi mật khẩu"),
                onTap: changePassword,
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
