import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/provider/post_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/splash_page.dart';
import 'routes/app_routes.dart';
import 'pages/setting_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("chat_app");
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
      title: 'Flutter Chat',
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashPage(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.register: (context) => const RegisterPage(),
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.setting: (context) => const SettingPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.chat) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverId: args['receiverId'],
              receiverName: args['receiverName'],
              receiverAvatar: args['receiverAvatar'],
            ),
          );
        }
        return null;
      },
    );
  }
}
