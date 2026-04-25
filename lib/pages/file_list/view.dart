import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/widgets/show_info_bar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final NetSession _session = NetSession();
  late TreeViewController _treeController = TreeViewController(
    items: [
      TreeViewItem(
        content: GestureDetector(
          child: Row(
            children: [
              Icon(FluentIcons.folder_24_regular, size: 16),
              SizedBox(width: 8),
              Text('根目录'),
            ],
          ),
          onTap: () {
            _loadFileList('0');
            setState(() {
              _breadItems.clear();
              _breadFiles.clear();
              _breadItems.add(BreadcrumbItem(label: Text('根目录'), value: 0));
              _breadFiles.add('0');
            });
          },
        ),
        value: '0',
        lazy: true,
        children: [],
      ),
    ],
  );
  List<FileItemModel> _fileList = [];
  FileItemModel? _selectedFile;
  int _currentParentId = 0;
  bool _isLoading = false;

  final List<String> _breadFiles = ['0'];
  final _breadItems = <BreadcrumbItem<int>>[
    BreadcrumbItem(label: Text('根目录'), value: 0),
  ];

  final commandBarKey = GlobalKey<CommandBarState>();

  @override
  void initState() {
    super.initState();
    _loadFileList('0');
    // 初始加载根目录的子文件夹
    _loadRootTreeItems();
  }

  Future<void> _loadRootTreeItems() async {
    try {
      final response = await _session.getFileList('0');
      if (response.apiCode == 200) {
        final List<FileItemModel> infoList = response.data.data.infoList;
        final children = infoList
            .where((FileItemModel file) => file.isFolder)
            .map(
              (FileItemModel file) => TreeViewItem(
                content: GestureDetector(
                  child: Row(
                    children: [
                      Icon(FluentIcons.folder_24_regular, size: 16),
                      SizedBox(width: 8),
                      Text(file.fileName),
                    ],
                  ),
                  onTap: () {
                    final childFileId = file.fileId.toString();
                    _loadFileList(childFileId);

                    // 更新面包屑
                    final fileNames = <String>[];
                    final fileIds = <String>[];
                    _collectBreadcrumbPath(
                      _treeController.items,
                      childFileId,
                      fileNames,
                      fileIds,
                    );

                    setState(() {
                      _breadItems.clear();
                      _breadFiles.clear();

                      for (int i = 0; i < fileNames.length; i++) {
                        _breadItems.add(
                          BreadcrumbItem(
                            label: Expanded(
                              child: Text(
                                fileNames[i],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            value: i,
                          ),
                        );
                        _breadFiles.add(fileIds[i]);
                      }
                    });
                  },
                ),
                value: file.fileId.toString(),
                lazy: true,
                children: [],
              ),
            )
            .toList();

        final updatedController = TreeViewController(
          items: _updateTreeItems(_treeController.items, '0', children),
        );

        setState(() {
          _treeController = updatedController;
        });
      }
    } catch (e) {
      debugPrint('加载根目录树形结构失败: $e');
    }
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
        // 重新尝试登录
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

  List<TreeViewItem> _updateTreeItems(
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
        children: _updateTreeItems(item.children, targetId, children),
        expanded: item.expanded,
      );
    }).toList();
  }

  bool _collectBreadcrumbPath(
    List<TreeViewItem> items,
    String targetId,
    List<String> names,
    List<String> ids,
  ) {
    for (final item in items) {
      names.add(
        (item.content as GestureDetector).child is Row
            ? ((item.content as GestureDetector).child as Row).children[2]
                      is Text
                  ? ((item.content as GestureDetector).child as Row).children[2]
                            is Text
                        ? (((item.content as GestureDetector).child as Row)
                                      .children[2]
                                  as Text)
                              .data!
                        : '未知'
                  : '未知'
            : '未知',
      );
      ids.add(item.value as String);

      if (item.value == targetId) {
        return true;
      }

      if (_collectBreadcrumbPath(item.children, targetId, names, ids)) {
        return true;
      }

      names.removeLast();
      ids.removeLast();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                child: const Row(
                  children: [
                    Icon(FluentIcons.arrow_left_24_regular),
                    SizedBox(width: 4),
                    Text('上一级'),
                  ],
                ),
                onPressed: () {
                  if (_breadItems.length > 1) {
                    _loadFileList(_breadFiles[_breadItems.length - 2]);
                    setState(() {
                      _breadItems.removeRange(
                        _breadItems.length - 1,
                        _breadItems.length,
                      );
                      _breadFiles.removeRange(
                        _breadFiles.length - 1,
                        _breadFiles.length,
                      );
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BreadcrumbBar(
                  items: _breadItems,
                  onItemPressed: (item) {
                    setState(() {
                      final index = _breadItems.indexOf(item);
                      _breadItems.removeRange(index + 1, _breadItems.length);
                      _breadFiles.removeRange(index + 1, _breadFiles.length);
                      _loadFileList(_breadFiles.last);
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                flex: 2,
                child: Card(
                  child: Center(
                    child: TreeView(
                      controller: _treeController,
                      onItemExpandToggle: (item, getsExpanded) async {
                        if (getsExpanded) {
                          final fileId = item.value as String;
                          try {
                            final response = await _session.getFileList(fileId);
                            if (response.apiCode == 200) {
                              final List<FileItemModel> infoList =
                                  response.data.data.infoList;
                              final children = infoList
                                  .where((FileItemModel file) => file.isFolder)
                                  .map(
                                    (FileItemModel file) => TreeViewItem(
                                      content: GestureDetector(
                                        child: Row(
                                          children: [
                                            Icon(
                                              FluentIcons.folder_24_regular,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                file.fileName,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          final childFileId = file.fileId
                                              .toString();
                                          _loadFileList(childFileId);

                                          // 更新面包屑
                                          final fileNames = <String>[];
                                          final fileIds = <String>[];
                                          _collectBreadcrumbPath(
                                            _treeController.items,
                                            childFileId,
                                            fileNames,
                                            fileIds,
                                          );

                                          setState(() {
                                            _breadItems.clear();
                                            _breadFiles.clear();

                                            for (
                                              int i = 0;
                                              i < fileNames.length;
                                              i++
                                            ) {
                                              _breadItems.add(
                                                BreadcrumbItem(
                                                  label: Expanded(
                                                    child: Text(
                                                      fileNames[i],
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  value: i,
                                                ),
                                              );
                                              _breadFiles.add(fileIds[i]);
                                            }
                                          });
                                        },
                                      ),
                                      value: file.fileId.toString(),
                                      lazy: true,
                                      children: [],
                                    ),
                                  )
                                  .toList();

                              final updatedController = TreeViewController(
                                items: _updateTreeItems(
                                  _treeController.items,
                                  fileId,
                                  children,
                                ),
                              );

                              setState(() {
                                _treeController = updatedController;
                              });
                            }
                          } catch (e) {
                            debugPrint('加载树形结构失败: $e');
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 6,
                child: Card(
                  child: Column(
                    children: [
                      CommandBar(
                        key: commandBarKey,
                        overflowBehavior:
                            CommandBarOverflowBehavior.dynamicOverflow,
                        primaryItems: [
                          CommandBarButton(
                            icon: const WindowsIcon(FluentIcons.add_24_regular),
                            label: const Text('新建'),
                            tooltip: '新建文件/文件夹',
                            onPressed: () async {
                              var result = await showDialog<String>(
                                context: context,
                                builder: (context) => const AddContentDialog(),
                              );

                              if (result != null) {
                                if (result.endsWith('/')) {
                                  result = result.substring(
                                    0,
                                    result.length - 1,
                                  );
                                  await _session.createDir(
                                    result,
                                    _currentParentId.toString(),
                                  );
                                  _loadFileList(_currentParentId.toString());
                                }
                              }
                            },
                          ),
                          CommandBarButton(
                            icon: const WindowsIcon(
                              FluentIcons.delete_24_regular,
                            ),
                            label: const Text('删除'),
                            tooltip: '删除选中文件',
                            onPressed: _selectedFile != null
                                ? () async {
                                    bool? result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          const TrashContentDialog(),
                                    );

                                    if (!mounted || !(result ?? false)) return;

                                    ApiReturnModel returnModel = await _session
                                        .trashFile(_selectedFile!);
                                    if (!mounted) return;

                                    if (returnModel.apiCodeEnum ==
                                        ApiCode.success) {
                                      _loadFileList(
                                        _currentParentId.toString(),
                                      );
                                      _selectedFile = null;
                                    } else {
                                      showInfoBar(
                                        // ignore: use_build_context_synchronously
                                        context,
                                        '错误',
                                        returnModel.msg,
                                        InfoBarSeverity.error,
                                      );
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),

                      !_isLoading
                          ? Expanded(
                              child: ListView.builder(
                                itemCount: _fileList.length,
                                itemBuilder: (context, index) {
                                  final file = _fileList[index];
                                  return ListTile.selectable(
                                    leading: getFileIcon(file),
                                    title: Text(file.fileName),
                                    subtitle: Text(
                                      file.isFolder
                                          ? '文件夹 - ${formatSize(file.size)}'
                                          : formatSize(file.size),
                                    ),
                                    trailing: Text(formatDate(file.updateAt)),
                                    selected: _selectedFile == file,
                                    onPressed: () {
                                      if (file.isFolder) {
                                        _loadFileList(file.fileId.toString());
                                        _breadFiles.add(file.fileId.toString());
                                        _breadItems.add(
                                          BreadcrumbItem(
                                            label: Text(
                                              file.fileName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            value: _breadItems.length + 1,
                                          ),
                                        );
                                      } else {
                                        setState(() => _selectedFile = file);
                                      }
                                    },
                                  );
                                },
                              ),
                            )
                          : Center(child: ProgressRing()),
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

class AddContentDialog extends StatefulWidget {
  const AddContentDialog({super.key});

  @override
  State<AddContentDialog> createState() => _AddContentDialogState();
}

class _AddContentDialogState extends State<AddContentDialog> {
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _createFile() async {
    final fileName = _fileNameController.text;
    if (fileName.isEmpty) {
      showInfoBar(context, '错误', '请输入文件名', InfoBarSeverity.error);
      return;
    }
    Navigator.pop(context, fileName);
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('新建'),
      content: InfoLabel(
        label:
            '在当前目录下新建文件/文件夹'
            '\n如果需要创建文件夹, 请在文件名后添加 /\n不支持多个 /',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextBox(controller: _fileNameController, placeholder: '请输入文件名'),
          ],
        ),
      ),

      actions: [
        FilledButton(
          child: Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
        Button(onPressed: _createFile, child: Text('新建')),
      ],
    );
  }
}

class TrashContentDialog extends StatefulWidget {
  const TrashContentDialog({super.key});

  @override
  State<TrashContentDialog> createState() => _TrashContentDialogState();
}

class _TrashContentDialogState extends State<TrashContentDialog> {
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('删除'),
      content: const Text('确认删除选中文件吗?\n删除后的文件将会放入回收站中'),
      actions: [
        FilledButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context, false),
        ),
        Button(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    );
  }
}
