import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/common/app_session.dart';

class DownloaderPage extends StatefulWidget {
  const DownloaderPage({super.key});

  @override
  State<DownloaderPage> createState() => _DownloaderPageState();
}

class _DownloaderPageState extends State<DownloaderPage> {
  final AppSession appSession = Get.find();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '传输',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Row(
                    children: [
                      ComboBox(
                        value: '全部',
                        items: [
                          ComboBoxItem(value: '全部', child: Text('全部')),
                          ComboBoxItem(
                            value: '下载',
                            child: Row(
                              children: [
                                const WindowsIcon(
                                  FluentIcons.arrow_download_24_regular,
                                ),
                                const SizedBox(width: 5),
                                Text('下载'),
                              ],
                            ),
                          ),
                          ComboBoxItem(
                            value: '上传',
                            child: Row(
                              children: [
                                const WindowsIcon(
                                  FluentIcons.arrow_upload_24_regular,
                                ),
                                const SizedBox(width: 5),
                                Text('上传'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {},
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: TextBox(placeholder: '过滤: 文件名')),
                      const SizedBox(width: 10),
                      const Text('排序: '),
                      ComboBox(
                        value: '文件名',
                        items: [
                          ComboBoxItem(value: '文件名', child: Text('文件名')),
                          ComboBoxItem(value: '文件大小', child: Text('文件大小')),
                        ],
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: Row(
                            children: [
                              Icon(
                                FluentIcons.arrow_download_24_regular,
                                color: appSession.accentColor.value,
                                size: 24,
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                getFileIconDataBySuffix('mp4'),
                                color: appSession.accentColor.value,
                                size: 24,
                              ),
                            ],
                          ),
                          title: Text('Demo Video.mp4'),
                          subtitle: Row(
                            children: [
                              ProgressBar(value: 100),
                              const SizedBox(width: 5),
                              Text('100% (1GB/1GB)'),
                            ],
                          ),
                          trailing: Row(
                            children: [
                              IconButton(
                                icon: Icon(FluentIcons.dismiss_24_regular),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(
                                  FluentIcons.more_vertical_24_regular,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: Row(
                            children: [
                              Icon(
                                FluentIcons.arrow_download_24_regular,
                                size: 24,
                              ),
                              const SizedBox(width: 5),
                              Icon(getFileIconDataBySuffix('txt'), size: 24),
                            ],
                          ),
                          title: Text('Demo File 1.txt'),
                          subtitle: Row(
                            children: [
                              ProgressBar(value: 50),
                              const SizedBox(width: 5),
                              Text('50% (100MB/200MB) (100MB/s)'),
                            ],
                          ),
                          trailing: Row(
                            children: [
                              IconButton(
                                icon: Icon(FluentIcons.pause_24_regular),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(FluentIcons.dismiss_24_regular),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(
                                  FluentIcons.more_vertical_24_regular,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: Row(
                            children: [
                              Icon(
                                FluentIcons.arrow_upload_24_regular,
                                size: 24,
                              ),
                              const SizedBox(width: 5),
                              Icon(getFileIconDataBySuffix('zip'), size: 24),
                            ],
                          ),
                          title: Text('Demo File 2.zip'),
                          subtitle: Row(
                            children: [
                              ProgressBar(value: 20),
                              const SizedBox(width: 5),
                              Text('20% (40MB/200MB) (40MB/s)'),
                            ],
                          ),
                          trailing: Row(
                            children: [
                              IconButton(
                                icon: Icon(FluentIcons.pause_24_regular),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(FluentIcons.dismiss_24_regular),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(
                                  FluentIcons.more_vertical_24_regular,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),

                        ListTile(
                          leading: Row(
                            children: [
                              Icon(
                                FluentIcons.arrow_download_24_regular,
                                size: 24,
                              ),
                              const SizedBox(width: 5),
                              Icon(FluentIcons.dismiss_24_regular, size: 24),
                              const SizedBox(width: 5),
                              Icon(getFileIconDataBySuffix('txt'), size: 24),
                            ],
                          ),
                          title: Text('Demo File 3.txt'),
                          subtitle: Row(
                            children: [
                              ProgressBar(value: 0),
                              const SizedBox(width: 5),
                              Text('10% (20MB/200MB) (0MB/s)'),
                            ],
                          ),
                          trailing: Row(
                            children: [
                              IconButton(
                                icon: Icon(FluentIcons.dismiss_24_regular),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(
                                  FluentIcons.more_vertical_24_regular,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
