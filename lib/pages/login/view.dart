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
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isLogin = false;

  void login() {
    setState(() => isLogin = true);

    if (userNameController.text.isEmpty || passwordController.text.isEmpty) {
      showInfoBar(context, '登录失败', '用户名或密码不能为空', InfoBarSeverity.error);
      setState(() => isLogin = false);
      return;
    }

    control
        .login(
          userNameController.text,
          passwordController.text,
          autoLogin,
          rememberPassword,
        )
        .then((value) {
          if (value.apiCodeEnum == ApiCode.success) {
            widget.onLoginSuccess();
          } else {
            if (!mounted) return;
            showInfoBar(context, '登录失败', value.msg, InfoBarSeverity.error);
          }
        });

    setState(() => isLogin = false);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '欢迎!',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),
          TextBox(placeholder: '用户名(邮箱/手机号)', controller: userNameController),
          SizedBox(height: 10),
          PasswordBox(placeholder: '密码', controller: passwordController),

          SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                checked: rememberPassword,
                onChanged: (_) =>
                    setState(() => rememberPassword = !rememberPassword),
              ),
              SizedBox(width: 5),
              Text('保存密码'),

              SizedBox(width: 15),
              Checkbox(
                checked: autoLogin,
                onChanged: (_) => setState(() {
                  if (!rememberPassword && !autoLogin) {
                    rememberPassword = true;
                  }
                  autoLogin = !autoLogin;
                }),
              ),
              SizedBox(width: 5),
              Text('自动登录'),
            ],
          ),

          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: login,
                child: Text(isLogin ? '登录中' : '登录'),
              ),
              SizedBox(width: 5),
              Button(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
