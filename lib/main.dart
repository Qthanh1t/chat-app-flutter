import 'package:chat_app/pages/create_group_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/provider/post_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/conversation_model.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/splash_page.dart';
import 'routes/app_routes.dart';
import 'pages/setting_page.dart';
import 'package:chat_app/service/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("chat_app");
  await ApiClient.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Z-Chat',
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashPage(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.register: (context) => const RegisterPage(),
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.setting: (context) => const SettingPage(),
        AppRoutes.createGroup: (context) => const CreateGroupPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.chat) {
          final args = settings.arguments;

          if (args is Conversation) {
            return MaterialPageRoute(
              builder: (context) => ChatPage(
                conversation: args,
              ),
            );
          }
          return _errorRoute("Lỗi: Dữ liệu hội thoại không hợp lệ.");
        }

        return _errorRoute("Lỗi: Không tìm thấy trang.");
      },
    );
  }

  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lỗi'),
          ),
          body: Center(
            child: Text(message),
          ),
        );
      },
    );
  }
}
