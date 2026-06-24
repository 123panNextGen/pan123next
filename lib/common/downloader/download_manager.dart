import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/downloader/download_task.dart';
import 'package:pan123next/common/downloader/download_config.dart';
import 'package:pan123next/common/downloader/download_engine.dart';
import 'package:pan123next/common/downloader/download_store.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final DownloadStore _store = DownloadStore();
  final DownloadConfig _config = DownloadConfig();
  final Map<String, DownloadTask> _tasks = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, PauseToken> _pauseTokens = {};
  final _onTaskUpdatedController = StreamController<DownloadTask>.broadcast();

  bool _initialized = false;
  int _activeCount = 0;

  Stream<DownloadTask> get onTaskUpdated => _onTaskUpdatedController.stream;
  List<DownloadTask> get tasks => _tasks.values.toList(growable: false);
  int get activeCount => _activeCount;
  int get pendingCount => tasks.where((t) => t.status == DownloadStatus.pending).length;
  int get downloadingCount => tasks.where((t) => t.status == DownloadStatus.downloading).length;
  int get completedCount => tasks.where((t) => t.status == DownloadStatus.completed).length;
  int get failedCount => tasks.where((t) => t.status == DownloadStatus.failed).length;
  int get pausedCount => tasks.where((t) => t.status == DownloadStatus.paused).length;

  Future<void> init() async {
    if (_initialized) return;
    final saved = await _store.loadTasks();
    for (final task in saved) {
      if (task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.paused;
      }
      _tasks[task.id] = task;
      _emitUpdate(task);
    }
    _initialized = true;
  }

  DownloadTask? getTask(String id) => _tasks[id];

  Future<DownloadTask> createTask({
    required FileItemModel file,
    required String savePath,
    required String downloadUrl,
    Map<String, String>? headers,
  }) async {
    final task = DownloadTask(
      id: const Uuid().v4(),
      file: file,
      savePath: savePath,
      downloadUrl: downloadUrl,
      headers: headers,
      totalBytes: file.size,
    );
    _tasks[task.id] = task;
    await _store.saveTask(task);
    _emitUpdate(task);
    return task;
  }

  Future<void> start(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.completed) return;

    task.chunkProgress = null;

    if (task.status != DownloadStatus.paused) {
      task.errorMessage = null;
      task.retryCount = 0;
    }

    if (_activeCount >= _config.maxConcurrentTasks) {
      task.status = DownloadStatus.pending;
      task.updatedAt = DateTime.now();
      _emitUpdate(task);
      await _store.saveTask(task);
      return;
    }

    task.status = DownloadStatus.downloading;
    task.updatedAt = DateTime.now();
    _activeCount++;
    if (task.totalBytes > _config.singleStreamThreshold) {
      task.chunkProgress = _buildChunkProgress(task.totalBytes);
    }
    _emitUpdate(task);

    final cancelToken = CancelToken();
    final pauseToken = PauseToken();
    _cancelTokens[taskId] = cancelToken;
    _pauseTokens[taskId] = pauseToken;
    final engine = DownloadEngine(config: _config);

    try {
      await engine.execute(
        task: task,
        onProgress: (received, total) {
          task.totalBytes = total;
          if (task.chunkProgress == null) {
            task.receivedBytes = received;
          }
          _emitUpdate(task);
        },
        onChunkProgress: (index, received, size) {
          if (task.chunkProgress != null && index < task.chunkProgress!.length) {
            task.chunkProgress![index].receivedBytes = received;
            task.receivedBytes = task.chunkProgress!
                .fold<int>(0, (sum, cp) => sum + cp.receivedBytes);
            _emitUpdate(task);
          }
        },
        cancelToken: cancelToken,
        pauseToken: pauseToken,
      );
      task.status = DownloadStatus.completed;
      task.receivedBytes = task.totalBytes;
      task.completedAt = DateTime.now();
      task.chunkProgress = null;
    } on CancelException {
      task.status = DownloadStatus.cancelled;
    } on PauseException {
      // Status already set to paused by pause()
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
    } finally {
      _activeCount--;
      task.updatedAt = DateTime.now();
      _cancelTokens.remove(taskId);
      _pauseTokens.remove(taskId);
      _emitUpdate(task);
      await _store.saveTask(task);
      _startNextPending();
    }
  }

  Future<void> pause(String taskId) async {
    final task = _tasks[taskId];
    if (task == null || task.status != DownloadStatus.downloading) return;
    _pauseTokens[taskId]?.requestPause();
    task.status = DownloadStatus.paused;
    task.updatedAt = DateTime.now();
    _emitUpdate(task);
    await _store.saveTask(task);
  }

  Future<void> cancel(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    _cancelTokens[taskId]?.cancel();
    _cancelTokens.remove(taskId);
    _pauseTokens.remove(taskId);
    task.status = DownloadStatus.cancelled;
    task.updatedAt = DateTime.now();
    _emitUpdate(task);
    await _store.saveTask(task);
    _cleanupTempFiles(task);
  }

  Future<void> remove(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    _cancelTokens[taskId]?.cancel();
    _cancelTokens.remove(taskId);
    _pauseTokens.remove(taskId);
    _tasks.remove(taskId);
    await _store.removeTask(taskId);
    // 下载完成的任务只删除任务，保留文件
    if (task.status != DownloadStatus.completed) {
      _cleanupTempFiles(task);
    }
    _emitUpdate(task);
  }

  Future<void> retry(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    task.chunkProgress = null;
    task.status = DownloadStatus.pending;
    task.errorMessage = null;
    task.retryCount = 0;
    task.updatedAt = DateTime.now();
    _emitUpdate(task);
    await _store.saveTask(task);
    _startNextPending();
  }

  void _startNextPending() {
    if (_activeCount >= _config.maxConcurrentTasks) return;
    final pending = tasks.where((t) => t.status == DownloadStatus.pending).toList();
    if (pending.isEmpty) return;
    start(pending.first.id);
  }

  void _emitUpdate(DownloadTask task) {
    _onTaskUpdatedController.add(task);
  }

  Future<void> _cleanupTempFiles(DownloadTask task) async {
    final tmpDir = Directory('${task.savePath}.pan123');
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
    final tmpFile = File('${task.savePath}.pan123');
    if (await tmpFile.exists()) {
      await tmpFile.delete();
    }
  }

  List<ChunkProgress> _buildChunkProgress(int totalBytes) {
    final chunks = <ChunkProgress>[];
    int offset = 0;
    int index = 0;
    while (offset < totalBytes) {
      final end = min(offset + _config.chunkSize - 1, totalBytes - 1);
      chunks.add(ChunkProgress(index: index, start: offset, end: end));
      offset = end + 1;
      index++;
    }
    return chunks;
  }

  void dispose() {
    _onTaskUpdatedController.close();
  }
}
