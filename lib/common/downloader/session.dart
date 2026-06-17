import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/data/downloader.dart';
import 'model.dart';

/// 外部 URL（非 123pan）使用的最小请求头。
const Map<String, String> _kExternalHeaders = {
  'user-agent': 'pan123next/2.4.0',
  'accept-encoding': 'gzip',
};

class DownloadSession extends GetxController {
  static final DownloadSession _instance = DownloadSession._internal();
  factory DownloadSession() => _instance;
  DownloadSession._internal();

  Map<String, dynamic> headers = {};
  UserInfoModel? _userInformation;

  final List<DownloadItemModel> _downloadList = [];
  final Map<String, DownloadTask> _tasks = {};

  final StreamController<DownloadItemModel> _progressController =
      StreamController.broadcast();
  final StreamController<List<DownloadItemModel>> _listController =
      StreamController.broadcast();

  bool _isInitialized = false;

  UserInfoModel? get userInformation => _userInformation;

  void setUserInformation(UserInfoModel userInfo) {
    _userInformation = userInfo;
    _updateHeaders();
  }

  void updateUserInfo(UserInfoModel userInfo) {
    _userInformation = userInfo;
    _updateHeaders();
  }

  void addDownloadListListener(Function(List<DownloadItemModel>) listener) {
    _listController.stream.listen(listener);
  }

  Stream<DownloadItemModel> get progressStream => _progressController.stream;
  Stream<List<DownloadItemModel>> get listStream => _listController.stream;
  List<DownloadItemModel> get downloadList => List.unmodifiable(_downloadList);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await DownloaderDb().initDb();

    // 初始化 background_downloader
    await FileDownloader().start();

    // 设置更新监听
    FileDownloader().updates.listen((update) {
      _handleUpdate(update);
    });

    await _loadDownloadList();
    _isInitialized = true;
  }

  void _updateHeaders() {
    if (_userInformation == null) return;
    headers = NetSession.buildHeadersForUser(_userInformation!);
  }

  /// 处理 background_downloader 的更新
  void _handleUpdate(TaskUpdate update) {
    switch (update) {
      case TaskStatusUpdate():
        final item = _findItemByTaskId(update.task.taskId);
        if (item != null) {
          final errorMsg = update.exception?.toString();
          item.updateFromTaskStatus(update.status, error: errorMsg);
          if (update.status == TaskStatus.running) {
            item.startTime ??= DateTime.now();
          }
          _notifyProgress(item);
          _saveDownloadList();
          _notifyListChange();
        }
      case TaskProgressUpdate():
        final item = _findItemByTaskId(update.task.taskId);
        if (item != null) {
          item.updateFromProgress(update);
          _notifyProgress(item);
        }
    }
  }

  DownloadItemModel? _findItemByTaskId(String taskId) {
    for (final item in _downloadList) {
      if (item.taskId == taskId) {
        return item;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 持久化
  // ---------------------------------------------------------------------------

  Future<void> _loadDownloadList() async {
    final db = Get.find<DownloaderDb>();
    final List<dynamic> listJson = db.getValue('downloadList') ?? [];

    _downloadList.clear();
    for (final jsonStr in listJson) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final item = DownloadItemModel.fromJson(jsonMap);

        // 重启后，未完成任务一律标记为 pending（避免悬挂的 downloading 状态）
        if (item.status == DownloadStatus.downloading) {
          item.status = DownloadStatus.pending;
        }

        // 已完成任务：如最终文件已被用户删除则丢弃任务条目
        if (item.status == DownloadStatus.completed) {
          if (!await File(item.savePath).exists()) continue;
        }

        _downloadList.add(item);
      } catch (_) {
        // 跳过已损坏的条目
      }
    }
    _notifyListChange();
  }

  Future<void> _saveDownloadList() async {
    final db = Get.find<DownloaderDb>();
    final listJson = _downloadList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    db.downloadList = listJson;
  }

  // ---------------------------------------------------------------------------
  // 公开 API
  // ---------------------------------------------------------------------------

  Future<DownloadItemModel> addDownload({
    required FileItemModel file,
    required String downloadUrl,
    String? savePath,
  }) async {
    await _ensureInitialized();

    final existingTask = _downloadList.firstWhere(
      (item) =>
          item.file.fileId == file.fileId &&
          item.status != DownloadStatus.completed,
      orElse: () =>
          DownloadItemModel(file: file, savePath: '', downloadUrl: ''),
    );

    if (existingTask.savePath.isNotEmpty) {
      return existingTask;
    }

    final path = savePath ?? await _getDefaultSavePath(file.fileName);

    final downloadItem = DownloadItemModel(
      file: file,
      savePath: path,
      downloadUrl: downloadUrl,
      totalSize: file.size,
    );

    _downloadList.add(downloadItem);
    await _saveDownloadList();
    _notifyListChange();

    await startDownload(downloadItem);

    return downloadItem;
  }

  Future<String> _getDefaultSavePath(String fileName) async {
    final directory = await getDownloadsDirectory();
    return '${directory!.path}/$fileName';
  }

  /// 添加一个非 123pan 的外部 URL 下载任务
  Future<DownloadItemModel> addExternalDownload({
    required String url,
    required String savePath,
    String? fileName,
  }) async {
    await _ensureInitialized();

    final name = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : _filenameFromUrl(url);

    // 同 URL 且未完成的任务去重
    final existing = _downloadList.firstWhere(
      (item) =>
          item.isExternal &&
          item.downloadUrl == url &&
          item.status != DownloadStatus.completed,
      orElse: () => DownloadItemModel(
        file: _placeholderFile(0, ''),
        savePath: '',
        downloadUrl: '',
      ),
    );
    if (existing.savePath.isNotEmpty) return existing;

    final syntheticId = -DateTime.now().microsecondsSinceEpoch;
    final placeholder = _placeholderFile(syntheticId, name);

    final downloadItem = DownloadItemModel(
      file: placeholder,
      savePath: savePath,
      downloadUrl: url,
      isExternal: true,
    );

    _downloadList.add(downloadItem);
    await _saveDownloadList();
    _notifyListChange();

    await startDownload(downloadItem);

    return downloadItem;
  }

  String _filenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  FileItemModel _placeholderFile(int id, String name) {
    return FileItemModel(
      fileId: id,
      fileName: name,
      type: 0,
      size: 0,
      etag: '',
      s3keyFlag: '',
      contentType: '',
      createAt: '',
      updateAt: '',
      hidden: false,
      parentFileId: 0,
      pinYin: '',
      starredStatus: false,
    );
  }

  Future<void> startDownload(DownloadItemModel item) async {
    await _ensureInitialized();

    if (item.status == DownloadStatus.downloading) return;

    // 确保保存目录存在
    final file = File(item.savePath);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final filename = file.uri.pathSegments.last;
    final directory = parentDir.path;

    // 创建 DownloadTask
    final task = DownloadTask(
      url: item.downloadUrl,
      filename: filename,
      directory: directory,
      baseDirectory: BaseDirectory.root,
      headers: item.isExternal
          ? _kExternalHeaders
          : Map<String, String>.from(headers),
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
      metaData: jsonEncode({
        'fileId': item.file.fileId,
        'isExternal': item.isExternal,
      }),
    );

    item.taskId = task.taskId;
    item.status = DownloadStatus.downloading;
    item.startTime ??= DateTime.now();
    _tasks[task.taskId] = task;
    await _saveDownloadList();
    _notifyProgress(item);

    // 使用 enqueue 启动后台下载
    final success = await FileDownloader().enqueue(task);
    if (!success) {
      item.status = DownloadStatus.failed;
      item.errorMessage = '无法启动下载任务';
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    }
  }

  void pauseDownload(DownloadItemModel item) {
    if (item.taskId == null) return;

    final task = _tasks[item.taskId!];
    if (task != null) {
      FileDownloader().pause(task);
    }
    item.status = DownloadStatus.paused;
    item.speed = 0;
    _notifyProgress(item);
    _saveDownloadList();
    _notifyListChange();
  }

  void resumeDownload(DownloadItemModel item) {
    if (item.taskId == null) return;

    final task = _tasks[item.taskId!];
    if (task != null) {
      FileDownloader().resume(task);
    }
    item.status = DownloadStatus.downloading;
    _notifyProgress(item);
    _saveDownloadList();
    _notifyListChange();
  }

  void pauseAllDownloads() {
    for (final item in _downloadList) {
      if (item.status == DownloadStatus.downloading) {
        pauseDownload(item);
      }
    }
  }

  Future<void> removeDownload(DownloadItemModel item) async {
    if (item.taskId != null) {
      await FileDownloader().cancelTaskWithId(item.taskId!);
      _tasks.remove(item.taskId!);
    }
    _downloadList.remove(item);

    // 清理临时文件
    final file = File(item.savePath);
    if (await file.exists()) {
      await file.delete();
    }

    await _saveDownloadList();
    _notifyListChange();
  }

  void clearCompleted() {
    _downloadList.removeWhere(
      (item) => item.status == DownloadStatus.completed,
    );
    _saveDownloadList();
    _notifyListChange();
  }

  // ---------------------------------------------------------------------------
  // 辅助方法
  // ---------------------------------------------------------------------------

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  void _notifyProgress(DownloadItemModel item) {
    _progressController.add(item);
  }

  void _notifyListChange() {
    _listController.add(List.unmodifiable(_downloadList));
  }
}
