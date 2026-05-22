import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:pan123next/common/i18n/i18n.dart';
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
        icon: Padding(
          padding: EdgeInsetsGeometry.all(2.0),
          child: Image.asset('assets/image/app_icon.png'),
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
        header: Text('login.header'.i),

        items: [
          PaneItem(
            icon: const Icon(FluentIcons.password_24_regular),
            title: Text('login.tab.password'.i),
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
            title: Text('login.tab.qrcode'.i),
            body: Center(child: Text('login.qrcode.placeholder'.i)),
          ),
        ],
      ),
    );
  }
}
