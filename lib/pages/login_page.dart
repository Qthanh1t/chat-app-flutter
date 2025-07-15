import 'package:chat_app/routes/app_navigator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../constants/api_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final box = Hive.box("chat_app");

  Future<void> login() async {
    try {
      final dio = Dio();
      dio.options.headers["Content-Type"] = "application/json";
      final response = await dio.post(
        "$baseUrl/users/login",
        data: {
          "email": emailController.text,
          "password": passwordController.text
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        box.put("token", data["token"]);
        box.put("userId", data["user"]["id"]);
        box.put("username", data["user"]["username"]);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng nhập thành công!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        AppNavigator.goToHome(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sai thông tin đăng nhập!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng nhập"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email")),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("Đăng nhập")),
            TextButton(
              onPressed: () {
                AppNavigator.goToRegister(context);
              },
              child: const Text("Chưa có tài khoản? Đăng ký"),
            )
          ],
        ),
      ),
    );
  }
}
