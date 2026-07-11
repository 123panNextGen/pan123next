import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/const.dart';
import 'package:pan123next/common/data/neo/neo_db.dart';
import 'package:pan123next/widgets/window_buttons.dart';
import 'package:pan123next/pages/login/view.dart';
import 'package:pan123next/pages/login/user_list_view.dart';
import 'package:window_manager/window_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});

  final Function() onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showUserList = false;
  bool _hasChecked = false;
  int _topIndex = 0;
  String? _loginUserName;

  @override
  void initState() {
    super.initState();
    _checkNeoDb();
  }

  Future<void> _checkNeoDb() async {
    final neoDb = Get.find<NeoDb>();
    final hasUsers = await neoDb.hasUsers();
    if (!mounted) return;
    setState(() {
      _showUserList = hasUsers;
      _hasChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasChecked) {
      return const Center(child: ProgressRing());
    }

    if (_showUserList) {
      return NavigationView(
        titleBar: TitleBar(
          icon: Padding(
            padding: const EdgeInsetsGeometry.all(2.0),
            child: Image(
              image: AssetImage(
                FluentTheme.of(context).brightness == Brightness.dark
                    ? 'assets/image/app_icon.png'
                    : 'assets/image/app_icon_white.png',
              ),
            ),
          ),
          title: Text(screenTitle),
          subtitle: const Text(screenSubTitle),
          captionControls: const WindowButtons(),
          onDragStarted: () => windowManager.startDragging(),
          onDoubleTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        pane: NavigationPane(
          selected: 0,
          displayMode: PaneDisplayMode.top,
          indicator: StickyNavigationIndicator(),
          header: const Text('选择账户'),
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.person_24_regular),
              title: const Text('选择账户'),
              body: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: UserListView(
                  onLoginSuccess: widget.onLoginSuccess,
                  onAddNewUser: () => setState(() => _showUserList = false),
                  onLoginAsUser: (user) => setState(() {
                    _loginUserName = user.userName;
                    _showUserList = false;
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NavigationView(
      titleBar: TitleBar(
        icon: Padding(
          padding: const EdgeInsetsGeometry.all(2.0),
          child: Image(
            image: AssetImage(
              FluentTheme.of(context).brightness == Brightness.dark
                  ? 'assets/image/app_icon.png'
                  : 'assets/image/app_icon_white.png',
            ),
          ),
        ),
        title: Text(screenTitle),
        subtitle: const Text(screenSubTitle),
        captionControls: const WindowButtons(),
        onDragStarted: () => windowManager.startDragging(),
        onDoubleTap: () async {
          if (await windowManager.isMaximized()) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        },
      ),
      pane: NavigationPane(
        selected: _topIndex,
        onChanged: (index) => setState(() => _topIndex = index),
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
              child: LoginInputPage(
                onLoginSuccess: widget.onLoginSuccess,
                onCancel: () => setState(() {
                  _showUserList = true;
                  _loginUserName = null;
                }),
                initialUserName: _loginUserName,
              ),
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
