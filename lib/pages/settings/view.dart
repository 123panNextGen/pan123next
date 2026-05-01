import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/get_platform.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  List<Map> themes = [
    {'value': 'dark', 'label': '暗色'},
    {'value': 'light', 'label': '亮色'},
  ];
  List<Map> accentColors = [
    {'value': 'purple', 'label': '紫色'},
    {'value': 'blue', 'label': '蓝色'},
    {'value': 'yellow', 'label': '黄色'},
    {'value': 'red', 'label': '红色'},
    {'value': 'green', 'label': '绿色'},
  ];

  String theme = AppDb().getValue('theme') ?? 'dark';
  String accentColor = AppDb().getValue('accentColor') ?? 'purple';

  @override
  Widget build(BuildContext context) {
    final AppSession appSession = Get.find();

    return FutureBuilder<String>(
      future: getVersion(),
      builder: (context, snapshot) {
        final version = snapshot.data ?? '获取版本中...';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '设置',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16.0),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(FluentIcons.dark_theme_24_regular),
                      SizedBox(width: 8.0),
                      Text('切换主题', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(child: const Text('主题')),
                      ComboBox<String>(
                        value: theme,
                        items: themes
                            .map(
                              (e) => ComboBoxItem<String>(
                                value: e['value'],
                                child: Text(e['label']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            theme = v;
                            setState(() {});
                            appSession.updateTheme(
                              v == 'dark' ? Brightness.dark : Brightness.light,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(child: const Text('颜色')),
                      ComboBox<String>(
                        value: accentColor,
                        items: accentColors
                            .map(
                              (e) => ComboBoxItem<String>(
                                value: e['value'],
                                child: Text(e['label']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            accentColor = v;
                            setState(() {});
                            appSession.updateAccentColor(v);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FluentIcons.info_24_regular),
                      const SizedBox(width: 8.0),
                      const Text('123Pan Next'),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text('当前版本: $version'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
