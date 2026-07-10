import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:pan123next/pages/file_list/file_list.dart';

class FileListTab extends Tab {
  FileListTab({
    super.key,
    required super.body,
    required super.text,
    Widget? icon,
  }) : _icon = icon;

  final Widget? _icon;

  @override
  Widget? get icon => _icon;

  @override
  State<Tab> createState() => _FileListTabState();
}

class _FileListTabState extends TabState {
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

  @override
  Widget build(BuildContext context) {
    return FlyoutTarget(
      key: _targetKey,
      controller: _flyoutController,
      child: super.build(context),
    );
  }
}

class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return TabView(
      currentIndex: _selectedIndex,
      onChanged: (index) => setState(() => _selectedIndex = index),
      tabWidthBehavior: TabWidthBehavior.sizeToContent,
      closeButtonVisibility: CloseButtonVisibilityMode.never,
      tabs: <Tab>[
        FileListTab(
          text: const Text('文件列表'),
          icon: const Icon(FluentIcons.folder_24_regular),
          body: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: const FileListWidget(isShowTrash: false),
          ),
        ),
        FileListTab(
          text: const Text('回收站'),
          icon: const Icon(FluentIcons.delete_24_regular),
          body: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: const FileListWidget(isShowTrash: true),
          ),
        ),
      ],
    );
  }
}
