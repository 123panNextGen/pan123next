import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:get/get.dart';
import 'package:pan123next/common/i18n/i18n.dart';
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

class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final NetSession _session = Get.find();
  List<FileItemModel> _fileList = [];
  FileItemModel? _selectedFile;
  int _currentParentId = 0;
  bool _isLoading = false;
  bool _isLoadFailed = false;

  final List<String> _breadItemIds = ['0'];
  final List<FileItemModel> _breadItemModels = [];
  final _breadItems = <BreadcrumbItem<int>>[
    BreadcrumbItem(label: Text('file.list.root'.i), value: 0),
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
      final response = await _session.getFileList(fileId);
      if (response.apiCode != 200) {
        if (retryCount >= 1) {
          if (!mounted) return;
          showInfoBar(
            context,
            'file.list.error'.i,
            'file.list.token.expired'.i,
            InfoBarSeverity.error,
          );
          return;
        }
        final loginResponse = await _session.login();
        if (loginResponse.apiCode != 200) {
          if (!mounted) return;
          showInfoBar(
            context,
            'file.list.error'.i,
            'file.list.token.expired'.i,
            InfoBarSeverity.error,
          );
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
      showInfoBar(
        context,
        'file.list.error'.i,
        'file.list.load.error'.i,
        InfoBarSeverity.error,
      );
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
    if (file.isFolder) {
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
      showInfoBar(
        context,
        'file.list.error'.i,
        returnModel.msg,
        InfoBarSeverity.error,
      );
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
      showInfoBar(
        context,
        'file.list.error'.i,
        returnModel.msg,
        InfoBarSeverity.error,
      );
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
          dialogTitle: 'file.list.save.path.title'.i,
          fileName: '${file.fileName}.zip',
          initialDirectory: defaultDownloadPath,
        );
      } else {
        fileResult = await FilePicker.saveFile(
          dialogTitle: 'file.list.save.path.title'.i,
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
      showInfoBar(
        context,
        'file.list.error'.i,
        result.msg,
        InfoBarSeverity.error,
      );
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
      'file.list.success'.i,
      'file.list.download.success'.iParams({'name': file.fileName}),
      InfoBarSeverity.success,
    );
  }

  Future<void> getFileDownloadLink(FileItemModel file) async {
    final ApiReturnModel result = await _session.getFileLink(file);
    final String fileName = file.fileName;

    if (result.apiCodeEnum == ApiCode.fail) {
      if (!mounted) return;
      showInfoBar(
        context,
        'file.list.error'.i,
        result.msg,
        InfoBarSeverity.error,
      );
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
        onPressed: () {
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
                    leading: const Icon(FluentIcons.folder_add_24_regular),
                    text: Text('file.list.add.folder'.i),
                    onPressed: () {
                      Flyout.of(context).close();
                      _handleAddFolder();
                    },
                  ),
                  MenuFlyoutItem(
                    leading: const Icon(FluentIcons.delete_24_regular),
                    text: Text('file.list.delete.current'.i),
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
            ? 'file.list.folder.format'.iParams({'size': formatSize(file.size)})
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
                  items: [
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.delete_24_regular),
                      text: Text('file.list.delete'.i),
                      onPressed: () {
                        Flyout.of(context).close();
                        _handleDelete();
                      },
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.rename_24_regular),
                      text: Text('file.list.rename'.i),
                      onPressed: () {
                        Flyout.of(context).close();
                        _handleRenameFile();
                      },
                    ),
                    MenuFlyoutSeparator(),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.link_24_regular),
                      text: Text('file.list.get.link'.i),
                      onPressed: () {
                        Flyout.of(context).close();
                        getFileDownloadLink(file);
                      },
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(
                        FluentIcons.arrow_download_24_regular,
                      ),
                      text: Text('file.list.download'.i),
                      onPressed: () {
                        Flyout.of(context).close();
                        downloadFile(file);
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
      primaryItems: [
        CommandBarButton(
          icon: const Icon(FluentIcons.arrow_repeat_all_24_regular),
          label: Text('file.list.refresh'.i),
          tooltip: 'file.list.refresh.tooltip'.i,
          onPressed: () => _loadFileList(_currentParentId.toString()),
        ),
        CommandBarButton(
          icon: const Icon(FluentIcons.folder_add_24_regular),
          label: Text('file.list.new.folder'.i),
          tooltip: 'file.list.new.folder.tooltip'.i,
          onPressed: _handleAddFolder,
        ),
        CommandBarButton(
          icon: const Icon(FluentIcons.delete_24_regular),
          label: Text('file.list.delete'.i),
          tooltip: 'file.list.delete.tooltip'.i,
          onPressed: _selectedFile != null ? _handleDelete : null,
        ),
        CommandBarButton(
          icon: const Icon(FluentIcons.rename_24_regular),
          label: Text('file.list.rename'.i),
          tooltip: 'file.list.rename.tooltip'.i,
          onPressed: _selectedFile != null ? _handleRenameFile : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'file.list.title'.i,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Row(
            children: [
              Button(
                onPressed: _breadItems.length > 1 ? _handleBack : null,
                child: Row(
                  children: [
                    const Icon(FluentIcons.arrow_left_24_regular),
                    const SizedBox(width: 4),
                    Text('file.list.back'.i),
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
                                : Expanded(
                                    child: Center(
                                      child: Text('file.list.empty'.i),
                                    ),
                                  ))
                          : const Expanded(
                              child: Center(child: ProgressRing()),
                            ))
                    : Expanded(
                        child: Center(child: Text('file.list.load.failed'.i)),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // 清理所有文件对应的 FlyoutController
    for (final controller in _flyoutControllers.values) {
      controller.dispose();
    }
    _flyoutControllers.clear();

    // 清理当前目录的 FlyoutController
    _currentFlyoutController.dispose();

    super.dispose();
  }
}
