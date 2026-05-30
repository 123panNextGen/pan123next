import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:pan123next/common/const.dart';
import 'package:pan123next/widgets/window_buttons.dart';
import 'package:pan123next/pages/login/view.dart';
import 'package:window_manager/window_manager.dart';

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
        icon: const Padding(
          padding: EdgeInsetsGeometry.all(2.0),
          child: Image(image: AssetImage('assets/image/app_icon.png')),
        ),
        title: Text(appName),
        subtitle: const Text('Preview'),
        captionControls: const WindowButtons(),
        onDragStarted: () => windowManager.startDragging(),
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.top,
        indicator: StickyNavigationIndicator(),
        header: const Text('登录'),

        items: [
          PaneItem(
            icon: const Icon(FluentIcons.password_24_regular),
            title: const Text('密码登录'),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: LoginInputPage(onLoginSuccess: widget.onLoginSuccess),
            ),
          ),
          PaneItem(
            icon: const Icon(WindowsIcons.q_r_code),
            title: const Text('扫码登录'),
            body: const Center(child: Text('二维码登录开发中...')),
          ),
        ],
      ),
    );
  }
}
