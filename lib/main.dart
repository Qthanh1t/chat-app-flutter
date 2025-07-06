import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'pages/login_page.dart';
import 'pages/home_page.dart';

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
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/users/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
