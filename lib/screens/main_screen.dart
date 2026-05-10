import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:pan123next/common/const.dart';
import 'package:pan123next/common/downloader/model.dart';
import 'package:pan123next/common/downloader/session.dart';
import 'package:pan123next/common/get_platform.dart';
import 'package:pan123next/pages/transfer/view.dart';
import 'package:pan123next/pages/file_list/view.dart';
import 'package:pan123next/pages/settings/view.dart';
import 'package:pan123next/widgets/window_buttons.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int topIndex = 0;
  int downloadCount = 0;

  void updateDownloadCount(List<DownloadItemModel> downloadList) {
    // 选择下载中的任务数量
    downloadCount = downloadList
        .where((element) => element.status != DownloadStatus.completed)
        .length;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DownloadSession().addDownloadListListener(updateDownloadCount);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      titleBar: TitleBar(
        icon: Padding(
          padding: EdgeInsetsGeometry.all(2.0),
          child: Image.asset('assets/image/app_icon.png'),
        ),
        title: Text(appName),
        subtitle: const Text('Preview'),
        captionControls: const WindowButtons(),
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: getPaneDisplayMode(),
        indicator: StickyNavigationIndicator(),
        header: const Text('主界面'),

        items: [
          PaneItem(
            icon: const Icon(FluentIcons.list_24_regular),
            title: const Text('文件列表'),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: FileListView(),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.arrow_download_24_regular),
            title: const Text('下载'),
            infoBadge: downloadCount > 0
                ? InfoBadge(source: Text(downloadCount.toString()))
                : const SizedBox(),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: const DownloaderPage(),
            ),
          ),
        ],

        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings_24_regular),
            title: const Text('设置'),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: const SettingsView(),
            ),
          ),
        ],
      ),
    );
  }
}
