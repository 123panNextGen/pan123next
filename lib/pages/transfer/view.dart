import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:pan123next/pages/transfer/list_view.dart';
import 'package:pan123next/pages/transfer/upload_view.dart';

class TransferTab extends Tab {
  TransferTab({
    super.key,
    required super.body,
    required super.text,
    Widget? icon,
  }) : _icon = icon;

  final Widget? _icon;

  @override
  Widget? get icon => _icon;

  @override
  State<Tab> createState() => _TransferTabState();
}

class _TransferTabState extends TabState {
  late FlyoutController _flyoutController;
  final _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _flyoutController = FlyoutController();
  }

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  void _showMenu(Offset position) {
    _flyoutController.showFlyout<void>(
      position: position,
      builder: (context) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              onPressed: () {
                Flyout.of(context).close();
              },
              leading: const Icon(FluentIcons.arrow_repeat_all_24_regular),
              text: const Text('刷新'),
            ),
            MenuFlyoutItem(
              onPressed: () {
                Flyout.of(context).close();
              },
              leading: const Icon(FluentIcons.dismiss_24_regular),
              text: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (d) {
        final targetContext = _targetKey.currentContext;
        if (targetContext == null) return;
        final box = targetContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(
          d.localPosition,
          ancestor: Navigator.of(context).context.findRenderObject(),
        );

        _showMenu(position);
      },
      child: FlyoutTarget(
        key: _targetKey,
        controller: _flyoutController,
        child: super.build(context),
      ),
    );
  }
}

class TransferView extends StatefulWidget {
  const TransferView({super.key});

  @override
  State<TransferView> createState() => _TransferViewState();
}

class _TransferViewState extends State<TransferView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return TabView(
      currentIndex: _selectedIndex,
      onChanged: (index) => setState(() => _selectedIndex = index),
      tabWidthBehavior: TabWidthBehavior.sizeToContent,
      closeButtonVisibility: CloseButtonVisibilityMode.never,
      tabs: <Tab>[
        TransferTab(
          text: const Text('下载中'),
          icon: const Icon(FluentIcons.arrow_download_24_regular),
          body: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: DownloadListView(),
          ),
        ),
        TransferTab(
          text: const Text('上传'),
          icon: const Icon(FluentIcons.arrow_upload_24_regular),
          body: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: UploadView(),
          ),
        ),
      ],
    );
  }
}
