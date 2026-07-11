import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/pages/login/control.dart' as control;
import 'package:pan123next/widgets/show_info_bar.dart';

class LoginInputPage extends StatefulWidget {
  const LoginInputPage({
    super.key,
    required this.onLoginSuccess,
    this.onCancel,
    this.initialUserName,
  });

  final Function() onLoginSuccess;
  final VoidCallback? onCancel;
  final String? initialUserName;

  @override
  State<LoginInputPage> createState() => _LoginInputPageState();
}

class _LoginInputPageState extends State<LoginInputPage> {
  bool rememberPassword = false;
  bool saveLoginInfo = false;
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = false;

  Future<void> login() async {
    setState(() => isLogin = true);

    if (userNameController.text.isEmpty || passwordController.text.isEmpty) {
      showInfoBar(context, '登录失败', '请输入用户名和密码', InfoBarSeverity.error);
      setState(() => isLogin = false);
      return;
    }

    try {
      final value = await control.login(
        userNameController.text,
        passwordController.text,
        rememberPassword,
        saveLoginInfo: saveLoginInfo,
      );
      if (!mounted) return;
      if (value.apiCodeEnum == ApiCode.success) {
        widget.onLoginSuccess();
      } else {
        showInfoBar(context, '登录失败', value.msg, InfoBarSeverity.error);
      }
    } finally {
      if (mounted) setState(() => isLogin = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialUserName != null) {
      userNameController.text = widget.initialUserName!;
      passwordController.text = '';
      rememberPassword = false;
      saveLoginInfo = false;
    } else {
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    final info = await control.getUserInfo();
    if (!mounted) return;
    setState(() {
      userNameController.text = info['userName'] ?? '';
      passwordController.text = info['password'] ?? '';
      rememberPassword = info['rememberPassword'] ?? false;
    });
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
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
                TextBox(placeholder: '用户名', controller: userNameController),
                const SizedBox(height: 10),
                PasswordBox(placeholder: '密码', controller: passwordController),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      checked: saveLoginInfo,
                      onChanged: (v) {
                        setState(() {
                          saveLoginInfo = v ?? false;
                          if (!saveLoginInfo) rememberPassword = false;
                        });
                      },
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => setState(() {
                        saveLoginInfo = !saveLoginInfo;
                        if (!saveLoginInfo) rememberPassword = false;
                      }),
                      child: const Text('保存登录信息'),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Checkbox(
                      checked: rememberPassword,
                      onChanged: (v) {
                        setState(() {
                          rememberPassword = v ?? false;
                          if (rememberPassword) saveLoginInfo = true;
                        });
                      },
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => setState(() {
                        rememberPassword = !rememberPassword;
                        if (rememberPassword) saveLoginInfo = true;
                      }),
                      child: Opacity(
                        opacity: saveLoginInfo ? 1.0 : 0.4,
                        child: const Text('记住密码'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(onPressed: login, child: const Text('登录')),
                    const SizedBox(width: 5),
                    Button(
                      onPressed: () {
                        if (widget.onCancel != null) {
                          widget.onCancel!();
                        } else {
                          Navigator.pop(context);
                          control.exitProgram();
                        }
                      },
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
