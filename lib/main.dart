import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zync/data/services/notification_services.dart';
import 'package:zync/modules/chat/view/chat_view.dart';
import 'package:zync/modules/home/view/home_view.dart';
import 'package:zync/modules/home/view/main_view.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'modules/auth/view/login_view.dart';
import 'modules/auth/view/register_view.dart';
import 'modules/auth/view/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  // Safe notification init — won't crash app if it fails
  try {
    await NotificationService().initialize();
  } catch (_) {}

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ZyncApp());
}

class ZyncApp extends StatelessWidget {
  const ZyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Zync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashView()),
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/register', page: () => const RegisterView()),
        GetPage(name: '/main', page: () => const MainView()),
        GetPage(name: '/chat', page: () => const ChatView()),
        // /home will be added in next step
      ],
    );
  }
}
