import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:get/get.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/user.dart';
import 'package:pan123next/common/downloader/session.dart';
import 'package:pan123next/common/format.dart';
import 'package:pan123next/widgets/show_info_bar.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dialog.dart';

class FileListWidget extends StatefulWidget {
  const FileListWidget({super.key, this.isShowTrash = false});

  final bool isShowTrash;

  @override
  State<FileListWidget> createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  final NetSession _session = Get.find();
  List<FileItemModel> _fileList = [];
  FileItemModel? _selectedFile;
  int _currentParentId = 0;
  bool _isLoading = false;
  bool _isLoadFailed = false;

  final List<String> _breadItemIds = ['0'];
  final List<FileItemModel> _breadItemModels = [];
  final _breadItems = <BreadcrumbItem<int>>[
    BreadcrumbItem(label: Text('根目录'), value: 0),
  ];

  final commandBarKey = GlobalKey<CommandBarState>();
  final Map<int, FlyoutController> _flyoutControllers = {};
  final FlyoutController _currentFlyoutController = FlyoutController();

  FlyoutController _getFlyoutController(int fileId) {
    return _flyoutControllers.putIfAbsent(fileId, () => FlyoutController());
  }

  @override
  void initState() {
    super.initState();
    _loadFileList('0');
  }

  Future<void> _loadFileList(String fileId, {int retryCount = 0}) async {
    setState(() {
      _isLoading = true;
      _currentParentId = int.parse(fileId);
      _selectedFile = null;
    });

    try {
      final response = widget.isShowTrash
          ? await _session.getTrashList(fileId)
          : await _session.getFileList(fileId);
      if (response.apiCode != 200) {
        if (retryCount >= 1) {
          if (!mounted) return;
          showInfoBar(context, '错误', 'Token 已过期且无法正常获取', InfoBarSeverity.error);
          return;
        }
        final loginResponse = await _session.login();
        if (loginResponse.apiCode != 200) {
          if (!mounted) return;
          showInfoBar(context, '错误', 'Token 已过期且无法正常获取', InfoBarSeverity.error);
          return;
        }
        if (!mounted) return;
        _loadFileList(fileId, retryCount: retryCount + 1);
        return;
      }
      setState(() {
        _fileList = response.data?.data.infoList ?? [];
        _isLoadFailed = false;
      });
    } catch (e) {
      debugPrint('加载文件列表失败: $e');
      setState(() => _isLoadFailed = true);
      if (!mounted) return;
      showInfoBar(context, '错误', '加载文件列表失败', InfoBarSeverity.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleBack() {
    if (_breadItems.length > 1) {
      _loadFileList(_breadItemIds[_breadItems.length - 2]);
      setState(() {
        _breadItems.removeRange(_breadItems.length - 1, _breadItems.length);
        _breadItemIds.removeRange(
          _breadItemIds.length - 1,
          _breadItemIds.length,
        );
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
    if (file.isFolder && !widget.isShowTrash) {
      _loadFileList(file.fileId.toString());
      setState(() {
        _breadItems.add(
          BreadcrumbItem(label: Text(file.fileName), value: file.fileId),
        );
        _breadItemIds.add(file.fileId.toString());
        _breadItemModels.add(file);
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

  Future<void> _handleDeleteCurrent() async {
    if (_currentParentId == 0) return;

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => const TrashCurrentDialog(),
    );

    if (!mounted || !(result ?? false)) return;

    final currentFile = _breadItemModels.last;
    ApiReturnModel returnModel = await _session.trashFile(currentFile);
    if (!mounted) return;

    if (returnModel.apiCodeEnum == ApiCode.success) {
      _loadFileList(_breadItemIds[_breadItems.length - 2]);
      setState(() {
        _breadItems.removeRange(_breadItems.length - 1, _breadItems.length);
        _breadItemIds.removeRange(
          _breadItemIds.length - 1,
          _breadItemIds.length,
        );
        _breadItemModels.removeRange(
          _breadItemModels.length - 1,
          _breadItemModels.length,
        );
      });
    } else {
      showInfoBar(context, '错误', returnModel.msg, InfoBarSeverity.error);
    }
  }

  Future<void> _handleRestoreFile() async {
    if (_selectedFile == null) return;

    ApiReturnModel returnModel = await _session.restoreFile(_selectedFile!);
    if (!mounted) return;

    if (returnModel.apiCodeEnum == ApiCode.success) {
      showInfoBar(context, '成功', '已成功恢复文件', InfoBarSeverity.success);
      _loadFileList(_currentParentId.toString());
      setState(() => _selectedFile = null);
    } else {
      showInfoBar(context, '错误', returnModel.msg, InfoBarSeverity.error);
    }
  }

  Future<void> _handleRenameFile() async {
    if (_selectedFile == null) return;

    String? result = await showDialog<String>(
      context: context,
      builder: (context) => RenameFileDialog(fileName: _selectedFile!.fileName),
    );

    if (result != null) {
      await _session.renameFile(_selectedFile!.fileId.toString(), result);
      _loadFileList(_currentParentId.toString());
    }
  }

  Future<void> downloadFile(FileItemModel file) async {
    String savePath;
    late String? fileResult;

    if (!Get.find<UserDb>().getValue('set.askDownload')) {
      savePath =
          Get.find<UserDb>().getValue('set.defaultDownloadPath') ??
          await getDownloadsDirectory().then((dir) => dir?.path ?? '');

      if (file.isFolder) {
        savePath = '$savePath/${file.fileName}.zip';
      } else {
        savePath = '$savePath/${file.fileName}';
      }
    } else {
      String defaultDownloadPath =
          Get.find<UserDb>().getValue('set.defaultDownloadPath') ??
          await getDownloadsDirectory().then((dir) => dir?.path ?? '');

      if (file.isFolder) {
        fileResult = await FilePicker.saveFile(
          dialogTitle: '选择保存路径:',
          fileName: '${file.fileName}.zip',
          initialDirectory: defaultDownloadPath,
        );
      } else {
        fileResult = await FilePicker.saveFile(
          dialogTitle: '选择保存路径:',
          fileName: file.fileName,
          initialDirectory: defaultDownloadPath,
        );
      }

      if (fileResult != null) {
      } else {
        return;
      }

      savePath = fileResult;
    }

    final ApiReturnModel result = await _session.getFileLink(file);

    if (result.apiCodeEnum == ApiCode.fail) {
      if (!mounted) return;
      showInfoBar(context, '错误', result.msg, InfoBarSeverity.error);
      return;
    }

    await Get.find<DownloadSession>().addDownload(
      file: file,
      downloadUrl: result.data,
      savePath: savePath,
    );

    if (!mounted) return;
    showInfoBar(
      context,
      '成功',
      '已成功下载: ${file.fileName}',
      InfoBarSeverity.success,
    );
  }

  Future<void> getFileDownloadLink(FileItemModel file) async {
    final ApiReturnModel result = await _session.getFileLink(file);
    final String fileName = file.fileName;

    if (result.apiCodeEnum == ApiCode.fail) {
      if (!mounted) return;
      showInfoBar(context, '错误', result.msg, InfoBarSeverity.error);
      return;
    }

    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          ShowDownloadLinkDialog(fileName: fileName, link: result.data),
    );
  }

  Widget _buildCurrentFlyout() {
    return FlyoutTarget(
      controller: _currentFlyoutController,
      child: IconButton(
        icon: const Icon(FluentIcons.more_vertical_24_regular),
        onPressed: widget.isShowTrash
            ? null
            : () {
                _currentFlyoutController.showFlyout<void>(
                  autoModeConfiguration: FlyoutAutoConfiguration(
                    preferredMode: FlyoutPlacementMode.bottomLeft,
                  ),
                  barrierDismissible: true,
                  dismissOnPointerMoveAway: false,
                  dismissWithEsc: true,
                  builder: (context) {
                    return MenuFlyout(
                      items: [
                        MenuFlyoutItem(
                          leading: const Icon(
                            FluentIcons.folder_add_24_regular,
                          ),
                          text: const Text('添加文件夹'),
                          onPressed: () {
                            Flyout.of(context).close();
                            _handleAddFolder();
                          },
                        ),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.delete_24_regular),
                          text: const Text('删除当前目录'),
                          onPressed: _currentParentId == 0
                              ? null
                              : () {
                                  Flyout.of(context).close();
                                  _handleDeleteCurrent();
                                },
                        ),
                      ],
                    );
                  },
                );
              },
      ),
    );
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
      trailing: FlyoutTarget(
        controller: _getFlyoutController(file.fileId),
        child: IconButton(
          icon: const Icon(FluentIcons.more_vertical_24_regular),
          onPressed: () {
            setState(() => _selectedFile = file);

            _getFlyoutController(file.fileId).showFlyout<void>(
              autoModeConfiguration: FlyoutAutoConfiguration(
                preferredMode: FlyoutPlacementMode.topCenter,
              ),
              barrierDismissible: true,
              dismissOnPointerMoveAway: false,
              dismissWithEsc: true,
              builder: (context) {
                return MenuFlyout(
                  items: !widget.isShowTrash
                      ? [
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.delete_24_regular),
                            text: const Text('删除'),
                            onPressed: () {
                              Flyout.of(context).close();
                              _handleDelete();
                            },
                          ),
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.rename_24_regular),
                            text: const Text('重命名'),
                            onPressed: () {
                              Flyout.of(context).close();
                              _handleRenameFile();
                            },
                          ),
                          MenuFlyoutSeparator(),
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.link_24_regular),
                            text: const Text('获取下载链接'),
                            onPressed: () {
                              Flyout.of(context).close();
                              getFileDownloadLink(file);
                            },
                          ),
                          MenuFlyoutItem(
                            leading: const Icon(
                              FluentIcons.arrow_download_24_regular,
                            ),
                            text: const Text('下载'),
                            onPressed: () {
                              Flyout.of(context).close();
                              downloadFile(file);
                            },
                          ),
                        ]
                      : [
                          MenuFlyoutItem(
                            leading: const Icon(
                              FluentIcons.arrow_reset_24_regular,
                            ),
                            text: const Text('恢复'),
                            onPressed: () {
                              Flyout.of(context).close();
                              _handleRestoreFile();
                            },
                          ),
                        ],
                );
              },
            );
          },
        ),
      ),
      selected: _selectedFile?.fileId == file.fileId,
      onPressed: () => _handleFileTap(file),
    );
  }

  Widget _buildCommandBar() {
    return CommandBar(
      key: commandBarKey,
      overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
      primaryItems: !widget.isShowTrash
          ? [
              CommandBarButton(
                icon: const Icon(FluentIcons.arrow_repeat_all_24_regular),
                label: const Text('刷新'),
                tooltip: '刷新文件列表',
                onPressed: () => _loadFileList(_currentParentId.toString()),
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.folder_add_24_regular),
                label: const Text('新建文件夹'),
                tooltip: '新建文件夹',
                onPressed: _handleAddFolder,
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.delete_24_regular),
                label: const Text('删除'),
                tooltip: '删除选中文件',
                onPressed: _selectedFile != null ? _handleDelete : null,
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.rename_24_regular),
                label: const Text('重命名'),
                tooltip: '重命名选中文件',
                onPressed: _selectedFile != null ? _handleRenameFile : null,
              ),
            ]
          : [
              CommandBarButton(
                icon: const Icon(FluentIcons.arrow_repeat_all_24_regular),
                label: const Text('刷新'),
                tooltip: '刷新文件列表',
                onPressed: () => _loadFileList(_currentParentId.toString()),
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.arrow_reset_24_regular),
                label: const Text('恢复'),
                tooltip: '恢复回收站中的选中文件',
                onPressed: _selectedFile != null ? _handleRestoreFile : null,
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.select_all_off_24_filled),
                label: const Text('取消'),
                tooltip: '取消选择的文件',
                onPressed: () => setState(() => _selectedFile = null),
              ),
            ],
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
                onPressed: _breadItems.length > 1 && !widget.isShowTrash
                    ? _handleBack
                    : null,
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
              const SizedBox(width: 8),
              _buildCurrentFlyout(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            child: Column(
              children: [
                _buildCommandBar(),
                !_isLoadFailed
                    ? (!_isLoading
                          ? (_fileList.isNotEmpty
                                ? Expanded(
                                    child: ListView.builder(
                                      itemCount: _fileList.length,
                                      itemBuilder: (context, index) =>
                                          _buildFileItem(_fileList[index]),
                                    ),
                                  )
                                : const Expanded(
                                    child: Center(child: Text('空空如也呢...')),
                                  ))
                          : const Expanded(
                              child: Center(child: ProgressRing()),
                            ))
                    : const Expanded(child: Center(child: Text('加载失败呜...'))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in _flyoutControllers.values) {
      controller.dispose();
    }
    _flyoutControllers.clear();

    _currentFlyoutController.dispose();

    super.dispose();
  }
}
