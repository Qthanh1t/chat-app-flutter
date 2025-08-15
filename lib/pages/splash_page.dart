import 'package:chat_app/service/api_client.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../routes/app_navigator.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    checkToken();
  }

  Future<void> checkToken() async {
    final box = Hive.box("chat_app");
    final token = box.get("token");

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigator.goToLogin(context);
      });
      return;
    }

    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.get("/users/me");

      if (response.statusCode == 200) {
        final data = response.data;
        box.put("userId", data["_id"]);
        box.put("username", data["username"]);
        box.put("avatar", data['avatar']);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNavigator.goToHome(context);
        });
      } else {
        box.delete("token");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNavigator.goToLogin(context);
        });
      }
    } catch (e) {
      box.delete("token");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigator.goToLogin(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
