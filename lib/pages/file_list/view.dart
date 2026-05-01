import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/common/get_platform.dart';
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
  late TreeViewController _treeController;
  List<FileItemModel> _fileList = [];
  FileItemModel? _selectedFile;
  int _currentParentId = 0;
  bool _isLoading = false;
  bool _isShowTree = isDesktop();

  List<String> _breadFiles = ['0'];
  List<BreadcrumbItem<int>> _breadItems = [
    const BreadcrumbItem(label: Text('根目录'), value: 0),
  ];

  final commandBarKey = GlobalKey<CommandBarState>();

  @override
  void initState() {
    super.initState();
    _initTreeController();
    _loadFileList('0');
  }

  void _initTreeController() {
    _treeController = TreeViewController(
      items: [
        TreeViewItem(
          content: _buildTreeItem('根目录', '0'),
          value: '0',
          lazy: true,
          children: [],
        ),
      ],
    );
  }

  Widget _buildTreeItem(String fileName, String fileId) {
    return InkWell(
      onTap: () {
        debugPrint('Tree item tapped: $fileName, $fileId');
        _navigateToFolder(fileName, fileId);
      },
      child: Row(
        children: [
          const Icon(FluentIcons.folder_24_regular, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(fileName, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ],
      ),
    );
  }

  void _navigateToFolder(String fileName, String fileId) {
    debugPrint('Navigating to folder: $fileName, $fileId');
    _loadFileList(fileId);
    _updateBreadcrumb(fileId, fileName);
  }

  void _updateBreadcrumb(String fileId, String fileName) {
    debugPrint(
      'Before update - breadFiles: $_breadFiles, fileId: $fileId, fileName: $fileName',
    );
    setState(() {
      if (fileId == '0') {
        _breadFiles = ['0'];
        _breadItems = [const BreadcrumbItem(label: Text('根目录'), value: 0)];
      } else {
        final currentIndex = _breadFiles.indexOf(fileId);
        if (currentIndex != -1) {
          _breadFiles = List.from(_breadFiles.sublist(0, currentIndex + 1));
          _breadItems = List.from(_breadItems.sublist(0, currentIndex + 1));
        } else {
          _breadFiles = List.from(_breadFiles)..add(fileId);
          _breadItems = List.from(_breadItems)
            ..add(
              BreadcrumbItem(label: Text(fileName), value: int.parse(fileId)),
            );
        }
      }
      debugPrint('Inside setState - breadFiles: $_breadFiles');
    });
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

  Future<void> _loadTreeChildren(String parentId) async {
    try {
      final response = await _session.getFileList(parentId);
      if (response.apiCode == 200) {
        final folders = response.data.data.infoList
            .where((f) => f.isFolder)
            .toList();
        final children = folders.map((folder) {
          return TreeViewItem(
            content: _buildTreeItem(folder.fileName, folder.fileId.toString()),
            value: folder.fileId.toString(),
            lazy: true,
            children: [],
          );
        }).toList();

        setState(() {
          _treeController = TreeViewController(
            items: _updateTreeNode(_treeController.items, parentId, children),
          );
        });
      }
    } catch (e) {
      debugPrint('加载树形结构失败: $e');
    }
  }

  List<TreeViewItem> _updateTreeNode(
    List<TreeViewItem> items,
    String targetId,
    List<TreeViewItem> children,
  ) {
    return items.map((item) {
      if (item.value == targetId) {
        return TreeViewItem(
          content: item.content,
          value: item.value,
          lazy: false,
          children: children,
          expanded: true,
        );
      }
      return TreeViewItem(
        content: item.content,
        value: item.value,
        lazy: item.lazy,
        children: _updateTreeNode(item.children, targetId, children),
        expanded: item.expanded,
      );
    }).toList();
  }

  void _handleBack() {
    if (_breadItems.length > 1) {
      final prevFileId = _breadFiles[_breadFiles.length - 2];
      final prevItem = _breadItems[_breadItems.length - 2];

      setState(() {
        _breadFiles.removeLast();
        _breadItems.removeLast();
      });

      _loadFileList(prevFileId);
    }
  }

  void _handleBreadcrumbTap(BreadcrumbItem<int> item) {
    final index = _breadItems.indexOf(item);
    setState(() {
      _breadFiles.removeRange(index + 1, _breadFiles.length);
      _breadItems.removeRange(index + 1, _breadItems.length);
    });
    _loadFileList(_breadFiles.last);
  }

  void _handleFileTap(FileItemModel file) {
    if (file.isFolder) {
      _navigateToFolder(file.fileName, file.fileId.toString());
    } else {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _handleAddFolder() async {
    final result = await showDialog<String>(
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const TrashContentDialog(),
    );

    if (!mounted || !(result ?? false)) return;

    final returnModel = await _session.trashFile(_selectedFile!);
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
      subtitle: Text(file.isFolder ? '文件夹' : formatSize(file.size)),
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
          child: Row(
            children: [
              if (_isShowTree) ...[
                Flexible(
                  flex: 2,
                  child: Card(
                    child: TreeView(
                      controller: _treeController,
                      onItemExpandToggle: (item, getsExpanded) {
                        if (getsExpanded) {
                          _loadTreeChildren(item.value as String);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                flex: _isShowTree ? 6 : 1,
                child: Card(
                  child: Column(
                    children: [
                      CommandBar(
                        key: commandBarKey,
                        overflowBehavior:
                            CommandBarOverflowBehavior.dynamicOverflow,
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
                            icon: const WindowsIcon(
                              FluentIcons.delete_24_regular,
                            ),
                            label: const Text('删除'),
                            tooltip: '删除选中文件',
                            onPressed: _selectedFile != null
                                ? _handleDelete
                                : null,
                          ),
                        ],
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: ProgressRing())
                            : ListView.builder(
                                itemCount: _fileList.length,
                                itemBuilder: (context, index) =>
                                    _buildFileItem(_fileList[index]),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
