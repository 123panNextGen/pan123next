import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/i18n/i18n.dart';
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
        'login.failed'.i,
        'login.empty.credentials'.i,
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
          'login.failed'.i,
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
                Text(
                  'login.welcome'.i,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),
                TextBox(
                  placeholder: 'login.username.placeholder'.i,
                  controller: userNameController,
                ),
                const SizedBox(height: 10),
                PasswordBox(
                  placeholder: 'login.password.placeholder'.i,
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
                    Text('login.remember.password'.i),

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
                    Text('login.auto.login'.i),
                  ],
                ),

                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: login,
                      child: Text('login.button'.i),
                    ),
                    SizedBox(width: 5),
                    Button(
                      onPressed: () => Navigator.pop(context),
                      child: Text('login.cancel'.i),
                    ),
                  ],
                ),
              ],
            )
          : ProgressRing(),
    );
  }
}
