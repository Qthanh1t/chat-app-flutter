import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import 'app_routes.dart';

class AppNavigator {
  // Đến màn Login và xoá toàn bộ stack
  static void goToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  // Đến màn Đăng ký
  static void goToRegister(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.register,
    );
  }

  // Đến màn Home và xoá toàn bộ stack
  static void goToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  // Đến màn Chat, truyền receiverId và receiverName
  static void goToChat(BuildContext context, Conversation conversation) {
    Navigator.of(context).pushNamed(
      AppRoutes.chat,
      arguments: conversation, // Truyền thẳng object
    );
  }

  //Đến màn hình setting
  static void goToSetting(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.setting,
    );
  }

  // Quay lại màn trước đó
  static void goBack(BuildContext context) {
    Navigator.of(context).pop();
  }
}
