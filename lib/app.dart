import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/const.dart';
import 'package:pan123next/screens/login_screen.dart';
import 'package:pan123next/screens/main_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // 注册主题变化监听器
    _registerThemeListener();
  }

  void _registerThemeListener() {
    final AppSession appSession = Get.find();
    // 监听主题变化
    ever(appSession.theme, (_) => setState(() {}));
    ever(appSession.accentColor, (_) => setState(() {}));
  }

  void onLoginSuccess() {
    setState(() => isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    final AppSession appSession = Get.find();

    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: FluentThemeData(
        brightness: appSession.theme.value,
        accentColor: appSession.accentColor.value,
      ),
      home: isLoggedIn
          ? const MainScreen()
          : LoginScreen(onLoginSuccess: onLoginSuccess),
    );
  }
}
