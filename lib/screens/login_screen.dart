import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/const.dart';
import 'package:pan123next/widgets/window_buttons.dart';
import 'package:pan123next/pages/login/view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});

  final Function() onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int topIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      titleBar: TitleBar(
        icon: const FlutterLogo(),
        title: Text(appName),
        subtitle: const Text('Preview'),
        captionControls: const WindowButtons(),
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.top,
        indicator: StickyNavigationIndicator(),
        header: const Text('登录'),

        items: [
          PaneItem(
            icon: const WindowsIcon(FluentIcons.input_address),
            title: const Text('用户名/密码 登录'),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: LoginInputPage(onLoginSuccess: widget.onLoginSuccess),
            ),
          ),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.q_r_code),
            title: const Text('二维码 登录'),
            body: Center(child: Text('作者其实很懒，什么都没有做呢~')),
          ),
        ],
      ),
    );
  }
}
