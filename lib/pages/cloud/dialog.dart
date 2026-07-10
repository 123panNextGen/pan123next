import 'package:fluent_ui/fluent_ui.dart';

class LogoutContentDialog extends StatefulWidget {
  const LogoutContentDialog({super.key});

  @override
  State<LogoutContentDialog> createState() => _LogoutContentDialogState();
}

class _LogoutContentDialogState extends State<LogoutContentDialog> {
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('退出登录'),
      content: const Text('确定要退出登录吗？'),
      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
