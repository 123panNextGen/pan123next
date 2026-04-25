import 'package:fluent_ui/fluent_ui.dart';
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
    AppSession().addThemeChangeListener((newTheme) {
      setState(() {}); // 触发重建以更新主题
    });
    // 注册主题变化监听器
    AppSession().addAccentColorChangeListener((newAccentColor) {
      setState(() {}); // 触发重建以更新主题颜色
    });
  }

  void onLoginSuccess() {
    setState(() => isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: FluentThemeData(
        brightness: AppSession().theme,
        accentColor: AppSession().accentColor,
      ),

      home: isLoggedIn
          ? MainScreen()
          : LoginScreen(onLoginSuccess: onLoginSuccess),
    );
  }
}
