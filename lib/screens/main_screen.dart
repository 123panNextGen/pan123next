import 'dart:async';
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
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int topIndex = 0;
  int downloadCount = 0;
  StreamSubscription<List<DownloadItemModel>>? _downloadListSubscription;

  void updateDownloadCount(List<DownloadItemModel> downloadList) {
    downloadCount = downloadList
        .where((element) => element.status != DownloadStatus.completed)
        .length;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _downloadListSubscription = DownloadSession().listStream.listen(
      updateDownloadCount,
    );
  }

  @override
  void dispose() {
    _downloadListSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      titleBar: TitleBar(
        icon: const Padding(
          padding: EdgeInsetsGeometry.all(2.0),
          child: Image(image: AssetImage('assets/image/app_icon.png')),
        ),
        title: Text(screenTitle),
        subtitle: const Text(screenSubTitle),
        captionControls: const WindowButtons(),
        onDragStarted: () => windowManager.startDragging(),
        onDoubleTap: () async {
          if (await windowManager.isMaximized()) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        },
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: getPaneDisplayMode(),
        indicator: StickyNavigationIndicator(),
        header: const Text('123云盘'),

        items: [
          PaneItem(
            icon: const Icon(FluentIcons.list_24_regular),
            title: const Text('文件'),
            body: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: FileListView(),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.arrow_download_24_regular),
            title: const Text('下载'),
            infoBadge: downloadCount > 0
                ? InfoBadge(source: Text(downloadCount.toString()))
                : const SizedBox(),
            body: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: DownloaderPage(),
            ),
          ),
        ],

        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings_24_regular),
            title: const Text('设置'),
            body: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: SettingsView(),
            ),
          ),
        ],
      ),
    );
  }
}
