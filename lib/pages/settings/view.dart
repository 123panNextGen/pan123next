import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/data/app.dart';
import 'package:pan123next/common/data/user.dart';
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
  late bool askDownload;
  late String language;
  late TextEditingController _downloadPathController;

  bool _picking = false;

  @override
  void initState() {
    super.initState();
    theme = appSession.getTheme();
    accentColor = appSession.getAccentColor();
    askDownload = Get.find<UserDb>().getValue('set.askDownload') ?? true;
    language = Get.find<UserDb>().getValue('set.language') ?? 'zh_CN';
    _downloadPathController = TextEditingController(
      text: Get.find<UserDb>().getValue('set.defaultDownloadPath') ?? '',
    );
  }

  @override
  void dispose() {
    _downloadPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getVersion(),
      builder: (context, snapshot) {
        final version = snapshot.data ?? '加载中...';

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
                  Row(
                    children: [
                      const Icon(FluentIcons.dark_theme_24_regular),
                      const SizedBox(width: 8.0),
                      const Text('外观', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Expanded(child: Text('主题')),
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
                      const Expanded(child: Text('主题色')),
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
                      const Icon(FluentIcons.arrow_download_24_regular),
                      const SizedBox(width: 8.0),
                      const Text('下载', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Expanded(child: Text('下载前询问保存位置')),
                      ToggleSwitch(
                        checked: askDownload,
                        onChanged: (v) {
                          askDownload = !askDownload;
                          Get.find<UserDb>().setValue(
                            'set.askDownload',
                            askDownload,
                            'bool',
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      const Expanded(child: Text('默认下载路径')),
                      Expanded(
                        child: TextBox(
                          controller: _downloadPathController,
                          placeholder: '请选择默认下载路径',
                          onChanged: (v) {
                            Get.find<UserDb>().setValue(
                              'set.defaultDownloadPath',
                              v,
                              'string',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        child: _picking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: ProgressRing(strokeWidth: 2),
                              )
                            : const Row(
                                children: [
                                  Icon(FluentIcons.folder_open_24_regular),
                                  SizedBox(width: 6),
                                  Text('选择'),
                                ],
                              ),
                        onPressed: () async {
                          setState(() => _picking = true);
                          final path = await FilePicker.getDirectoryPath();
                          if (path != null) {
                            Get.find<UserDb>().setValue(
                              'set.defaultDownloadPath',
                              path,
                              'string',
                            );
                          }
                          setState(() => _picking = false);
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
                      const Text('关于'),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text('当前版本：$version'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
