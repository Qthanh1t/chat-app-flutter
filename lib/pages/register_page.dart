import 'package:chat_app/routes/app_navigator.dart';
import 'package:chat_app/service/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController1 = TextEditingController();
  final passwordController2 = TextEditingController();

  Future<void> register() async {
    try {
      if ((passwordController1.text.isNotEmpty &&
              passwordController1.text.length < 6) ||
          (passwordController1.text.isEmpty)) {
        throw Exception("Mật khẩu phải chứa ít nhất 6 kí tự!");
      } else if (passwordController1.text != passwordController2.text) {
        throw Exception("Hãy nhập lại chính xác mật khẩu!");
      }
      final dio = ApiClient.instance.dio;
      dio.options.headers["Content-Type"] = "application/json";
      final response = await dio.post(
        "/users/register",
        data: {
          "username": usernameController.text,
          "email": emailController.text,
          "password": passwordController1.text,
        },
      );
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        AppNavigator.goToLogin(context);
      }
    } catch (err) {
      if (err is DioException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email đã tồn tại"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$err"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Tên người dùng")),
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email")),
            TextField(
                controller: passwordController1,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mật khẩu")),
            TextField(
                controller: passwordController2,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Nhập lại mật khẩu")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text("Đăng ký")),
          ],
        ),
      ),
    );
  }
}
