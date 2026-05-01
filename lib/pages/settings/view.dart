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
  final AppSession appSession = Get.find();
  late String theme;
  late String accentColor;

  @override
  void initState() {
    super.initState();
    theme = appSession.getTheme();
    accentColor = appSession.getAccentColor();

    debugPrint('theme: $theme, accentColor: $accentColor');
  }

  @override
  Widget build(BuildContext context) {
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
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: e['result'],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(e['label']),
                                  ],
                                ),
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
