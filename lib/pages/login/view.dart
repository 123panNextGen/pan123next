import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/pages/login/control.dart' as control;
import 'package:pan123next/widgets/show_info_bar.dart';

class LoginInputPage extends StatefulWidget {
  const LoginInputPage({super.key, required this.onLoginSuccess});

  final Function() onLoginSuccess;

  @override
  State<LoginInputPage> createState() => _LoginInputPageState();
}

class _LoginInputPageState extends State<LoginInputPage> {
  bool autoLogin = false;
  bool rememberPassword = false;
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = false;

  Future<void> login() async {
    setState(() => isLogin = true);

    if (userNameController.text.isEmpty || passwordController.text.isEmpty) {
      showInfoBar(
        context,
        '登录失败',
        '请输入用户名和密码',
        InfoBarSeverity.error,
      );
      setState(() => isLogin = false);
      return;
    }

    try {
      final value = await control.login(
        userNameController.text,
        passwordController.text,
        autoLogin,
        rememberPassword,
      );
      if (!mounted) return;
      if (value.apiCodeEnum == ApiCode.success) {
        widget.onLoginSuccess();
      } else {
        showInfoBar(
          context,
          '登录失败',
          value.msg,
          InfoBarSeverity.error,
        );
      }
    } finally {
      if (mounted) setState(() => isLogin = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> info = control.getUserInfo();
    setState(() {
      userNameController.text = info['userName'];
      passwordController.text = info['password'];
      autoLogin = info['autoLogin'];
      rememberPassword = info['rememberPassword'];
    });

    if (autoLogin) {
      login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: !isLogin
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '欢迎使用 123云盘',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),
                TextBox(
                  placeholder: '用户名',
                  controller: userNameController,
                ),
                const SizedBox(height: 10),
                PasswordBox(
                  placeholder: '密码',
                  controller: passwordController,
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      checked: rememberPassword,
                      onChanged: (_) =>
                          setState(() => rememberPassword = !rememberPassword),
                    ),
                    const SizedBox(width: 5),
                    const Text('记住密码'),

                    const SizedBox(width: 15),
                    Checkbox(
                      checked: autoLogin,
                      onChanged: (_) => setState(() {
                        if (!rememberPassword && !autoLogin) {
                          rememberPassword = true;
                        }
                        autoLogin = !autoLogin;
                      }),
                    ),
                    const SizedBox(width: 5),
                    const Text('自动登录'),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: login,
                      child: const Text('登录'),
                    ),
                    const SizedBox(width: 5),
                    Button(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ],
            )
          : const ProgressRing(),
    );
  }
}
