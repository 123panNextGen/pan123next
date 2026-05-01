import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/widgets/show_info_bar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'dialog.dart';

class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final NetSession _session = NetSession();
  List<FileItemModel> _fileList = [];
  FileItemModel? _selectedFile;
  int _currentParentId = 0;
  bool _isLoading = false;

  final List<String> _breadItemIds = ['0'];
  final _breadItems = <BreadcrumbItem<int>>[
    BreadcrumbItem(label: Text('根目录'), value: 0),
  ];

  final commandBarKey = GlobalKey<CommandBarState>();

  @override
  void initState() {
    super.initState();
    _loadFileList('0');
  }

  Future<void> _loadFileList(String fileId) async {
    setState(() {
      _isLoading = true;
      _currentParentId = int.parse(fileId);
      _selectedFile = null;
    });

    try {
      final response = await _session.getFileList(fileId);
      if (response.apiCode != 200) {
        final loginResponse = await _session.login();
        if (loginResponse.apiCode != 200) {
          if (!mounted) return;
          showInfoBar(context, '错误', 'Token 已过期且无法正常获取', InfoBarSeverity.error);
          return;
        } else {
          _loadFileList(fileId);
          return;
        }
      }
      setState(() {
        _fileList = response.data.data.infoList;
      });
    } catch (e) {
      debugPrint('加载文件列表失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleBack() {
    if (_breadItems.length > 1) {
      _loadFileList(_breadItemIds[_breadItems.length - 2]);
      setState(() {
        _breadItems.removeRange(_breadItems.length - 1, _breadItems.length);
        _breadItemIds.removeRange(_breadItemIds.length - 1, _breadItemIds.length);
      });
    }
  }

  void _handleBreadcrumbTap(BreadcrumbItem<int> item) {
    final index = _breadItems.indexOf(item);
    setState(() {
      _breadItems.removeRange(index + 1, _breadItems.length);
      _breadItemIds.removeRange(index + 1, _breadItemIds.length);
    });
    _loadFileList(_breadItemIds.last);
  }

  void _handleFileTap(FileItemModel file) {
    if (file.isFolder) {
      _loadFileList(file.fileId.toString());
      setState(() {
        _breadItems.add(
          BreadcrumbItem(label: Text(file.fileName), value: file.fileId),
        );
        _breadItemIds.add(file.fileId.toString());
      });
    } else {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _handleAddFolder() async {
    var result = await showDialog<String>(
      context: context,
      builder: (context) => const AddFolderDialog(),
    );

    if (result != null) {
      await _session.createDir(result, _currentParentId.toString());
      _loadFileList(_currentParentId.toString());
    }
  }

  Future<void> _handleDelete() async {
    if (_selectedFile == null) return;

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => const TrashContentDialog(),
    );

    if (!mounted || !(result ?? false)) return;

    ApiReturnModel returnModel = await _session.trashFile(_selectedFile!);
    if (!mounted) return;

    if (returnModel.apiCodeEnum == ApiCode.success) {
      _loadFileList(_currentParentId.toString());
      setState(() => _selectedFile = null);
    } else {
      showInfoBar(context, '错误', returnModel.msg, InfoBarSeverity.error);
    }
  }

  Widget _buildFileItem(FileItemModel file) {
    return ListTile.selectable(
      leading: getFileIcon(file),

      title: Text(file.fileName),
      subtitle: Text(
        file.isFolder
            ? '文件夹 - ${formatSize(file.size)}'
            : formatSize(file.size),
      ),
      trailing: Text(file.updateAt),
      selected: _selectedFile?.fileId == file.fileId,
      onPressed: () => _handleFileTap(file),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '文件列表',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Row(
            children: [
              Button(
                onPressed: _breadItems.length > 1 ? _handleBack : null,
                child: const Row(
                  children: [
                    Icon(FluentIcons.arrow_left_24_regular),
                    SizedBox(width: 4),
                    Text('上一级'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BreadcrumbBar(
                  items: _breadItems,
                  onItemPressed: _handleBreadcrumbTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            child: Column(
              children: [
                CommandBar(
                  key: commandBarKey,
                  overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
                  primaryItems: [
                    CommandBarButton(
                      icon: const WindowsIcon(
                        FluentIcons.arrow_repeat_all_24_regular,
                      ),
                      label: const Text('刷新'),
                      tooltip: '刷新文件列表',
                      onPressed: () =>
                          _loadFileList(_currentParentId.toString()),
                    ),
                    CommandBarButton(
                      icon: const WindowsIcon(
                        FluentIcons.folder_add_24_regular,
                      ),
                      label: const Text('新建文件夹'),
                      tooltip: '新建文件夹',
                      onPressed: _handleAddFolder,
                    ),
                    CommandBarButton(
                      icon: const WindowsIcon(FluentIcons.delete_24_regular),
                      label: const Text('删除'),
                      tooltip: '删除选中文件',
                      onPressed: _selectedFile != null ? _handleDelete : null,
                    ),
                  ],
                ),
                !_isLoading
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: _fileList.length,
                          itemBuilder: (context, index) =>
                              _buildFileItem(_fileList[index]),
                        ),
                      )
                    : const Expanded(child: Center(child: ProgressRing())),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
