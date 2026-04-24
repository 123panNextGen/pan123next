import 'package:fluent_ui/fluent_ui.dart';
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

  void onLoginSuccess() {
    setState(() => isLoggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.purple,
      ),

      home: isLoggedIn
          ? MainScreen()
          : LoginScreen(onLoginSuccess: onLoginSuccess),
    );
  }
}
