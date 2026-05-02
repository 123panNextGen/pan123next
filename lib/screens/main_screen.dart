import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:pan123next/common/const.dart';
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

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      titleBar: TitleBar(
        icon: const FlutterLogo(),
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
            icon: const WindowsIcon(FluentIcons.list_24_regular),
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
            icon: const WindowsIcon(FluentIcons.arrow_download_24_regular),
            title: const Text('下载'),
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
            icon: const WindowsIcon(FluentIcons.settings_24_regular),
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
