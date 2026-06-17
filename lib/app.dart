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
  void onLoginSuccess() {
    Get.find<AppSession>().isLoggedIn.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSession>(
      builder: (appSession) {
        return FluentApp(
          debugShowCheckedModeBanner: false,
          title: appName,
          locale: appSession.appLocale.value,
          theme: FluentThemeData(
            brightness: appSession.theme.value,
            accentColor: appSession.accentColor.value,
            fontFamily: 'MiSans',
          ),
          home: SafeArea(
            child: appSession.isLoggedIn.value
                ? const MainScreen()
                : LoginScreen(onLoginSuccess: onLoginSuccess),
          ),
        );
      },
    );
  }
}
