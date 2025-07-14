import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import '../constants/api_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("chat_app");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkToken() async {
    final box = Hive.box("chat_app");
    final token = box.get("token");
    if (token == null) return false;

    try {
      final dio = Dio();
      dio.options.headers["Authorization"] = "Bearer $token";
      final response = await dio.get(
        "$baseUrl/users/me",
      );

      if (response.statusCode == 200) {
        final data = response.data;
        box.put("userId", data["_id"]);
        box.put("username", data["username"]);
        return true;
      } else {
        box.delete("token");
        return false;
      }
    } catch (e) {
      box.delete("token");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final isLoggedIn = snapshot.data!;
        return MaterialApp(
          title: 'Flutter Chat',
          home: isLoggedIn ? const HomePage() : const LoginPage(),
        );
      },
    );
  }
}
