import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pan123next/common/downloader/go_bridge.dart';
import 'package:pan123next/common/api/model.dart';
import 'model.dart';

class DownloadSession extends GetxController {
  static final DownloadSession _instance = DownloadSession._internal();
  factory DownloadSession() => _instance;
  DownloadSession._internal();

  final DownloadServerBridge _bridge = DownloadServerBridge();
  DownloadServerClient? _client;

  final List<DownloadItemModel> _downloadList = [];
  StreamSubscription<List<Map<String, dynamic>>>? _pollSub;

  final StreamController<DownloadItemModel> _progressController =
      StreamController.broadcast();
  final StreamController<List<DownloadItemModel>> _listController =
      StreamController.broadcast();

  bool _running = false;

  /// 正在等待服务端确认的操作中的任务 ID 集合
  final Set<String> _pendingActions = {};

  // ---- 空闲自停 ----
  Timer? _idleTimer;
  static const _idleTimeout = Duration(seconds: 120);

  Stream<DownloadItemModel> get progressStream => _progressController.stream;
  Stream<List<DownloadItemModel>> get listStream => _listController.stream;
  List<DownloadItemModel> get downloadList => List.unmodifiable(_downloadList);
  bool get isRunning => _running;
  int get port => _bridge.port;

  UserInfoModel? get userInformation => null;

  void setUserInformation(UserInfoModel userInfo) {}
  void updateUserInfo(UserInfoModel userInfo) {}

  // ---------------------------------------------------------------------------
  // 生命周期
  // ---------------------------------------------------------------------------

  Future<bool> startServer() async {
    final dataDir = await _resolveDataDir();
    final ok = await _bridge.start(dataDir: dataDir);
    if (ok) {
      _client = DownloadServerClient(_bridge.port);
      _running = true;
      await _loadFromServer();
      _startPolling();
    }
    return ok;
  }

  Future<void> stopServer() async {
    _cancelIdleTimer();
    _pollSub?.cancel();
    await _bridge.stop();
    _running = false;
    _downloadList.clear();
  }

  Future<String> _resolveDataDir() async {
    if (Platform.isAndroid || Platform.isIOS) return '';
    try {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    } catch (_) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      } catch (_) {
        return '';
      }
    }
  }

  void _startPolling() {
    _pollSub?.cancel();
    _pollSub = _client!
        .pollProgress(interval: const Duration(milliseconds: 600))
        .listen((tasks) {
      _mergeTasks(tasks);
    });
  }

  void _mergeTasks(List<Map<String, dynamic>> serverTasks) {
    final serverMap = <String, Map<String, dynamic>>{};
    for (final t in serverTasks) {
      serverMap[t['id'] as String] = t;
    }

    for (final item in _downloadList) {
      final serverTask = serverMap.remove(item.taskId);
      if (serverTask != null) {
        if (_pendingActions.contains(item.taskId)) {
          item.updateProgressFromMap(serverTask);
        } else {
          item.updateFromServerMap(serverTask);
        }
        _notifyProgress(item);
      }
    }

    for (final entry in serverMap.entries) {
      if (_pendingActions.contains(entry.key)) continue;
      final t = DownloadItemModel.fromServerMap(entry.value);
      if (t != null) {
        _downloadList.add(t);
        _notifyListChange();
      }
    }

    _notifyListChange();
    _updateIdleTimer();
  }

  // ---- 空闲检测: 无活动任务 120s 后自动停服 ----

  void _updateIdleTimer() {
    if (!_running) return;
    if (_hasActiveTasks) {
      _cancelIdleTimer();
    } else {
      _idleTimer ??= Timer(_idleTimeout, _onIdleTimeout);
    }
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _onIdleTimeout() {
    _idleTimer = null;
    stopServer();
  }

  bool get _hasActiveTasks =>
      _downloadList.any((item) =>
          item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.pending);

  // ---------------------------------------------------------------------------
  // 公开 API
  // ---------------------------------------------------------------------------

  Future<DownloadItemModel?> addDownload({
    required FileItemModel file,
    required String downloadUrl,
    required String savePath,
  }) async {
    // 服务未运行则自动重启
    if (!_running) {
      final ok = await startServer();
      if (!ok) return null;
    }
    // 有新任务，取消空闲定时器
    _cancelIdleTimer();
    if (_client == null) return null;

    final result = await _client!.addTask(
      url: downloadUrl,
      savePath: savePath,
      fileName: file.fileName,
    );

    if (result == null) return null;

    final item = DownloadItemModel.fromServerMap(result);
    if (item != null) {
      _downloadList.add(item);
      _notifyListChange();
    }
    return item;
  }

  Future<bool> pauseDownload(DownloadItemModel item) async {
    _pendingActions.add(item.taskId);
    final ok = await _client?.pauseTask(item.taskId) ?? false;
    if (ok) {
      item.status = DownloadStatus.paused;
      _notifyProgress(item);
      _notifyListChange();
    }
    _pendingActions.remove(item.taskId);
    return ok;
  }

  Future<bool> resumeDownload(DownloadItemModel item) async {
    _pendingActions.add(item.taskId);
    final ok = await _client?.resumeTask(item.taskId) ?? false;
    if (ok) {
      item.status = DownloadStatus.pending;
      _notifyProgress(item);
      _notifyListChange();
    }
    _pendingActions.remove(item.taskId);
    return ok;
  }

  Future<bool> removeDownload(DownloadItemModel item) async {
    _pendingActions.add(item.taskId);
    final ok = await _client?.removeTask(item.taskId) ?? false;
    if (ok) {
      _downloadList.remove(item);
      _notifyListChange();
    }
    _pendingActions.remove(item.taskId);
    return ok;
  }

  Future<bool> clearCompleted() async {
    final ok = await _client?.clearCompleted() ?? false;
    if (ok) {
      _downloadList.removeWhere((i) => i.status == DownloadStatus.completed);
      _notifyListChange();
    }
    return ok;
  }

  // ---------------------------------------------------------------------------
  // 加载
  // ---------------------------------------------------------------------------

  Future<void> _loadFromServer() async {
    if (_client == null) return;
    final tasks = await _client!.listTasks();
    _downloadList.clear();
    for (final t in tasks) {
      final item = DownloadItemModel.fromServerMap(t);
      if (item != null) {
        _downloadList.add(item);
      }
    }
    _notifyListChange();
  }

  void _notifyProgress(DownloadItemModel item) {
    _progressController.add(item);
  }

  void _notifyListChange() {
    _listController.add(List.unmodifiable(_downloadList));
  }
}
