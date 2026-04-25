import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/get_platform.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late String version = '获取版本中...';
  Brightness theme = AppSession().theme;
  AccentColor accentColor = AppSession().accentColor;

  void updateVersion() async {
    version = await getVersion();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '设置',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),

        Expander(
          header: const Text('切换主题', style: TextStyle(fontSize: 16)),
          content: Row(
            children: [
              RadioGroup(
                groupValue: accentColor,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => accentColor = v);
                    AppSession().accentColor = v;
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioButton<AccentColor>(
                      value: Colors.blue,
                      content: const Text('蓝色'),
                      enabled: true,
                    ),
                    RadioButton<AccentColor>(
                      value: Colors.purple,
                      content: const Text('紫色'),
                      enabled: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              RadioGroup(
                groupValue: theme,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => theme = v);
                    AppSession().theme = v;
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioButton<Brightness>(
                      value: Brightness.dark,
                      content: const Text('暗色'),
                      enabled: true,
                    ),
                    RadioButton<Brightness>(
                      value: Brightness.light,
                      content: const Text('亮色'),
                      enabled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
