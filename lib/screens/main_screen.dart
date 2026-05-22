import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:pan123next/common/i18n/i18n.dart';
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

  void updateDownloadCount(List<DownloadItemModel> downloadList) {
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
        onDragStarted: () => windowManager.startDragging(),
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: getPaneDisplayMode(),
        indicator: StickyNavigationIndicator(),
        header: Text('main.header'.i),

        items: [
          PaneItem(
            icon: const Icon(FluentIcons.list_24_regular),
            title: Text('main.tab.files'.i),
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
            title: Text('main.tab.downloads'.i),
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
            title: Text('main.tab.settings'.i),
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
