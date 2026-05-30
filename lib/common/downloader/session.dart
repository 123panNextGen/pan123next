import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:path_provider/path_provider.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/api/session.dart';
import 'package:pan123next/common/data/downloader.dart';
import 'model.dart';

/// 单分片最多重试次数（不含首次尝试）。
const int _kMaxSegmentRetry = 3;

/// 进度持久化节流间隔。分片下载过程中每秒会有大量进度回调，
/// 通过节流避免每次都写 SharedPreferences。
const Duration _kPersistThrottle = Duration(milliseconds: 500);

/// 单分片连接 / 接收超时。
const Duration _kSegmentConnectTimeout = Duration(seconds: 30);
const Duration _kSegmentReceiveTimeout = Duration(seconds: 300);

/// 外部 URL（非 123pan）使用的最小请求头。
/// 不能携带 123pan 的 authorization / host 等头部 —— 否则会泄露用户凭据，
/// 且大多数 CDN 会因为 host 不匹配而拒绝请求。
const Map<String, String> _kExternalHeaders = {
  'user-agent': 'pan123next/2.4.0',
  'accept-encoding': 'gzip',
};

class DownloadSession extends GetxController {
  static final DownloadSession _instance = DownloadSession._internal();
  factory DownloadSession() => _instance;
  DownloadSession._internal();

  late final Dio _dio;
  Map<String, dynamic> headers = {};
  UserInfoModel? _userInformation;

  final List<DownloadItemModel> _downloadList = [];

  /// 每个任务持有的取消令牌（单线程下载 1 个，分片下载 N 个）。
  final Map<String, List<CancelToken>> _cancelTokens = {};
  final Map<String, _SpeedTracker> _speedTrackers = {};

  /// 节流持久化定时器；任务结束 / 暂停时强制 flush。
  final Map<String, Timer> _persistTimers = {};

  /// URL 刷新冷却：防止短时间内高频刷新触发服务端限流。
  static const Duration _kUrlRefreshCooldown = Duration(seconds: 30);
  final Map<String, DateTime> _lastRefreshTimes = {};

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

  Dio get dio {
    if (_userInformation == null) {
      throw Exception('请先调用 setUserInformation 设置用户信息');
    }
    return _dio;
  }

  Stream<DownloadItemModel> get progressStream => _progressController.stream;
  Stream<List<DownloadItemModel>> get listStream => _listController.stream;
  List<DownloadItemModel> get downloadList => List.unmodifiable(_downloadList);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await DownloaderDb().initDb();
    _initDio();
    await _loadDownloadList();
    _isInitialized = true;
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://www.123pan.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: false,
        error: true,
      ),
    );
  }

  /// 返回当前任务应使用的请求头：外部 URL 用最小集合，避免泄露 123pan 凭据；
  /// 123pan 文件继续使用完整鉴权头。
  Map<String, dynamic> _headersFor(DownloadItemModel item) {
    if (item.isExternal) {
      return Map<String, dynamic>.from(_kExternalHeaders);
    }
    return headers;
  }

  void _updateHeaders() {
    if (_userInformation == null) return;
    headers = NetSession.buildHeadersForUser(_userInformation!);
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

        // 重启后，未完成任务一律标记为 paused（避免悬挂的 downloading 状态）。
        if (item.status == DownloadStatus.downloading) {
          item.status = DownloadStatus.paused;
        }

        // 与磁盘对账，确保模型字段与文件实际状态一致。
        await _reconcileWithDisk(item);

        // 已完成任务：如最终文件已被用户删除则丢弃任务条目。
        if (item.status == DownloadStatus.completed) {
          if (!await File(item.savePath).exists()) continue;
          // 兜底清理可能残留的 .partN / .tmp（正常路径已删，这里二次保障）
          await _cleanupTaskTempFiles(item);
        }

        _downloadList.add(item);
      } catch (_) {
        // 跳过已损坏的条目，不影响其他记录加载
      }
    }
    _notifyListChange();
  }

  /// 与磁盘文件对账：根据实际文件大小修正 [item] 的 segments / downloadedSize。
  Future<void> _reconcileWithDisk(DownloadItemModel item) async {
    if (item.segments.isNotEmpty) {
      // 分片任务：逐片核对 .partN 实际大小
      var anyExist = false;
      var aggregate = 0;
      for (final seg in item.segments) {
        final segFile = File('${item.savePath}.part${seg.index}');
        if (await segFile.exists()) {
          anyExist = true;
          final actual = await segFile.length();
          if (actual < seg.downloaded) {
            // 内存记录大于实际：以实际为准
            seg.downloaded = actual;
            seg.completed = false;
          } else if (actual > seg.downloaded) {
            // 实际大于记录：最近一次持久化后又下载了若干字节，
            // 这些字节是合法数据（dio 按 chunk 入 sink），信任磁盘以避免重传。
            seg.downloaded = actual;
          }
          if (seg.downloaded == seg.expectedSize) {
            seg.completed = true;
          } else {
            seg.completed = false;
          }
        } else {
          // 分片文件丢失：重置该片
          seg.downloaded = 0;
          seg.completed = false;
        }
        aggregate += seg.downloaded;
      }
      if (!anyExist) {
        // 所有分片文件都不在了：清空分片，按全新任务对待
        item.segments = [];
        item.downloadedSize = 0;
      } else {
        item.downloadedSize = aggregate;
      }
      item.progress = item.totalSize > 0
          ? item.downloadedSize / item.totalSize
          : 0;
    } else {
      // 单线程任务：核对主文件
      final file = File(item.savePath);
      if (await file.exists()) {
        final actual = await file.length();
        if (actual != item.downloadedSize) {
          item.downloadedSize = actual;
        }
      } else {
        item.downloadedSize = 0;
      }
      item.progress = item.totalSize > 0
          ? item.downloadedSize / item.totalSize
          : 0;
    }
  }

  Future<void> _saveDownloadList() async {
    final db = Get.find<DownloaderDb>();
    final listJson = _downloadList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    db.prefs.setStringList('downloader.downloadList', listJson);
  }

  /// 节流：合并 [_kPersistThrottle] 内的多次写入为一次。
  void _persistThrottled(DownloadItemModel item) {
    final id = item.file.fileId.toString();
    _persistTimers[id]?.cancel();
    _persistTimers[id] = Timer(_kPersistThrottle, () {
      _saveDownloadList();
      _persistTimers.remove(id);
    });
  }

  /// 立即 flush 节流 buffer 并写入。任务结束 / 暂停时调用。
  Future<void> _persistFlush(DownloadItemModel item) async {
    final id = item.file.fileId.toString();
    _persistTimers[id]?.cancel();
    _persistTimers.remove(id);
    await _saveDownloadList();
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

  /// 添加一个非 123pan 的外部 URL 下载任务。
  ///
  /// 与 [addDownload] 不同，外部任务没有真实的 [FileItemModel]：
  /// 这里构造一个合成的占位模型，使用负的微秒时间戳作为 fileId，
  /// 避免与服务器返回的真实 fileId（正整数）发生冲突。
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

    // 合成 FileItemModel，fileId 用 -microsecondsSinceEpoch 保证唯一且不与真实 ID 冲突
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

  /// 从 URL 路径推导文件名。失败时回退为时间戳命名。
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

  /// 构造合成的 [FileItemModel]，专用于外部下载占位。
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

    item.status = DownloadStatus.downloading;
    item.errorMessage = null;
    item.startTime ??= DateTime.now();
    await _saveDownloadList();
    _notifyProgress(item);

    // 续传前用 HEAD 校验远端文件未被替换。
    final hasProgress = item.segments.isNotEmpty || item.downloadedSize > 0;
    if (hasProgress) {
      final ok = await _verifyRemoteFile(item);
      if (!ok) {
        item.status = DownloadStatus.failed;
        item.errorMessage ??= '远端文件已变更，请重新下载';
        _notifyProgress(item);
        await _persistFlush(item);
        _notifyListChange();
        return;
      }
    }

    if (item.segments.isNotEmpty) {
      // 已规划分片 → 分片续传 / 继续
      await _runSegmentedTask(item);
    } else if (item.downloadedSize > 0) {
      // 单线程续传
      await _resumeDownload(item);
    } else {
      // 全新任务
      await _startNewDownload(item);
    }
  }

  void pauseDownload(DownloadItemModel item) {
    final id = item.file.fileId.toString();
    final tokens = _cancelTokens[id];
    if (tokens != null) {
      for (final token in tokens) {
        if (!token.isCancelled) token.cancel();
      }
    }
    _speedTrackers.remove(id);
    item.status = DownloadStatus.paused;
    item.speed = 0;
    _notifyProgress(item);
    // 强制 flush，保证最新的分片进度落盘
    _persistFlush(item);
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
    pauseDownload(item);
    _downloadList.remove(item);
    // 清理与该任务关联的所有临时文件
    await _cleanupTaskTempFiles(item);
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
  // 全新下载（首次启动）
  // ---------------------------------------------------------------------------

  Future<void> _startNewDownload(DownloadItemModel item) async {
    final id = item.file.fileId.toString();

    try {
      await _getDownloadInfo(item);

      if (item.totalSize <= 0) {
        item.status = DownloadStatus.failed;
        item.errorMessage = '无法获取文件大小';
        _notifyProgress(item);
        await _persistFlush(item);
        _notifyListChange();
        return;
      }

      final parentDir = File(item.savePath).parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final segCount = _segmentCount(item.totalSize);
      if (segCount <= 1) {
        // 小文件，单线程下载
        final cancelToken = CancelToken();
        _cancelTokens[id] = [cancelToken];

        final file = File(item.savePath);
        await file.create(recursive: true);

        await _dio.download(
          item.downloadUrl,
          item.savePath,
          options: Options(
            headers: _headersFor(item),
            responseType: ResponseType.stream,
            receiveTimeout: _kSegmentReceiveTimeout,
          ),
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            _updateProgress(item, received, total);
            _persistThrottled(item);
          },
        );
        await _markCompleted(item);
      } else {
        // 大文件，规划分片并立即落盘 segments
        item.segments = _calculateSegments(item.totalSize, segCount);
        await _saveDownloadList();
        await _runSegmentedTask(item);
      }
    } catch (e) {
      _handleDownloadError(item, e);
    } finally {
      _cancelTokens.remove(id);
    }
  }

  // ---------------------------------------------------------------------------
  // 单线程续传
  // ---------------------------------------------------------------------------

  Future<void> _resumeDownload(DownloadItemModel item) async {
    if (!item.supportsResume) {
      item.downloadedSize = 0;
      item.segments = [];
      await _startNewDownload(item);
      return;
    }

    final cancelToken = CancelToken();
    final id = item.file.fileId.toString();
    _cancelTokens[id] = [cancelToken];

    try {
      final file = File(item.savePath);
      if (!await file.exists()) {
        item.downloadedSize = 0;
        await _startNewDownload(item);
        return;
      }

      final fileSize = await file.length();
      if (fileSize != item.downloadedSize) {
        item.downloadedSize = fileSize;
      }

      // 下载剩余部分到临时文件
      final tempPath = '${item.savePath}.tmp';
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final response = await _dio.download(
        item.downloadUrl,
        tempPath,
        options: Options(
          headers: {
            ..._headersFor(item),
            'range': 'bytes=${item.downloadedSize}-',
          },
          receiveTimeout: _kSegmentReceiveTimeout,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          _updateProgress(item, item.downloadedSize + received, item.totalSize);
          _persistThrottled(item);
        },
      );

      final statusCode = response.statusCode ?? 0;
      final tempSize = await tempFile.length();

      if (statusCode == 200) {
        // 服务器忽略 Range 返回了完整文件 —— 视为不支持断点续传。
        // 用临时文件直接替换原文件（tempSize == totalSize）。
        if (await tempFile.exists()) {
          if (await file.exists()) await file.delete();
          await tempFile.rename(item.savePath);
        }
        item.downloadedSize = tempSize;
        item.supportsResume = false;
      } else if (statusCode == 206) {
        // 从 Content-Range 确认文件总大小
        final contentRange = response.headers.value('content-range');
        if (contentRange != null) {
          final total = int.tryParse(contentRange.split('/').last);
          if (total != null && total > 0) {
            item.totalSize = total;
          }
        }

        // 追加临时文件到主文件
        const chunkSize = 8192;
        final src = await tempFile.open(mode: FileMode.read);
        final dest = await file.open(mode: FileMode.append);
        try {
          while (true) {
            final chunk = await src.read(chunkSize);
            if (chunk.isEmpty) break;
            await dest.writeFrom(chunk);
          }
        } finally {
          await src.close();
          await dest.close();
        }
        await tempFile.delete();
        item.downloadedSize += tempSize;
      } else {
        // 未预期的状态码
        await tempFile.delete();
        item.status = DownloadStatus.failed;
        item.errorMessage = '续传失败，状态码: $statusCode';
        _speedTrackers.remove(id);
        _notifyProgress(item);
        await _persistFlush(item);
        _notifyListChange();
        return;
      }

      // 验证文件完整性
      final finalSize = await file.length();
      if (finalSize < item.totalSize) {
        item.status = DownloadStatus.failed;
        item.errorMessage = '下载不完整，已下载: $finalSize 字节，总计: ${item.totalSize} 字节';
        _speedTrackers.remove(id);
        _notifyProgress(item);
        await _persistFlush(item);
        _notifyListChange();
      } else {
        await _markCompleted(item);
      }
    } catch (e) {
      // 清理临时文件
      final tempFile = File('${item.savePath}.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      _handleDownloadError(item, e);
    } finally {
      _cancelTokens.remove(id);
    }
  }

  // ---------------------------------------------------------------------------
  // 分片下载（首次 / 续传共用）
  // ---------------------------------------------------------------------------

  Future<void> _runSegmentedTask(DownloadItemModel item) async {
    final id = item.file.fileId.toString();
    _cancelTokens[id] = [];

    try {
      // 为每个未完成分片分配独立 CancelToken
      final pending = <SegmentInfo>[];
      for (final seg in item.segments) {
        if (seg.completed) continue;
        seg.cancelToken = CancelToken();
        _cancelTokens[id]!.add(seg.cancelToken!);
        pending.add(seg);
      }

      // 已经聚合一次进度（让 UI 立即体现已下载量）
      _aggregateSegmentsProgress(item);

      // 并发下载所有未完成分片，单片失败不取消其他片
      final results = await Future.wait(
        pending.map((seg) => _downloadSegmentWithRetry(item, seg)),
        eagerError: false,
      );

      final failures = results.whereType<Object>().toList();
      if (failures.isNotEmpty) {
        // 第一个非取消错误抛出
        final realError = failures.firstWhere(
          (e) => !(e is DioException && CancelToken.isCancel(e)),
          orElse: () => failures.first,
        );
        throw realError;
      }

      // 全部分片完成 → 合并
      await _mergeSegmentFiles(item, item.segments);
      await _markCompleted(item);
    } catch (e) {
      _handleDownloadError(item, e);
    } finally {
      _cancelTokens.remove(id);
    }
  }

  /// 下载单个分片，失败时按指数退避重试，401/403/410 触发 URL 刷新。
  ///
  /// 返回 null 表示成功；非 null 表示最终失败的异常对象。
  /// 取消（暂停）也以异常返回，由调用方在汇总阶段判断。
  Future<Object?> _downloadSegmentWithRetry(
    DownloadItemModel item,
    SegmentInfo seg,
  ) async {
    var attempt = 0;
    while (true) {
      try {
        await _downloadSegmentResumable(item, seg);
        seg.completed = true;
        await _persistFlush(item);
        return null;
      } catch (e) {
        // 暂停（cancel）直接终止重试，向上抛
        if (e is DioException && CancelToken.isCancel(e)) {
          return e;
        }

        // 鉴权 / URL 过期类错误：先尝试刷新 URL，刷新成功立即重试（不计入退避）
        if (e is DioException) {
          final code = e.response?.statusCode ?? 0;
          if (code == 401 || code == 403 || code == 410) {
            if (await _refreshDownloadUrl(item)) {
              continue;
            }
          }
        }

        if (attempt >= _kMaxSegmentRetry) {
          return e;
        }
        // 指数退避：1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << attempt));
        // 退避期间被取消（暂停）→ 立即终止，向上抛 cancel 语义异常
        if (seg.cancelToken?.isCancelled == true) {
          return DioException(
            requestOptions: RequestOptions(path: item.downloadUrl),
            type: DioExceptionType.cancel,
          );
        }
        attempt++;
      }
    }
  }

  /// 真正执行单分片下载。支持从 [SegmentInfo.downloaded] 处续传。
  ///
  /// 关键点：使用流式响应 + [FileMode.append] 手动写入，避免
  /// `Dio.download(url, path)` 默认覆盖目标文件导致已下载数据丢失。
  Future<void> _downloadSegmentResumable(
    DownloadItemModel item,
    SegmentInfo seg,
  ) async {
    final segFile = File('${item.savePath}.part${seg.index}');
    if (!await segFile.exists()) {
      await segFile.create(recursive: true);
      seg.downloaded = 0;
    } else {
      // 与磁盘对账（保险起见，第二次保障）
      final actual = await segFile.length();
      if (actual != seg.downloaded) {
        if (actual < seg.downloaded) {
          seg.downloaded = actual;
        } else {
          final raf = await segFile.open(mode: FileMode.append);
          try {
            await raf.truncate(seg.downloaded);
          } finally {
            await raf.close();
          }
        }
      }
    }

    final rangeStart = seg.start + seg.downloaded;
    if (rangeStart > seg.end) {
      seg.completed = true;
      return;
    }

    final response = await _dio.get<ResponseBody>(
      item.downloadUrl,
      options: Options(
        headers: {
          ..._headersFor(item),
          'range': 'bytes=$rangeStart-${seg.end}',
        },
        responseType: ResponseType.stream,
        receiveTimeout: _kSegmentReceiveTimeout,
        sendTimeout: _kSegmentConnectTimeout,
      ),
      cancelToken: seg.cancelToken,
    );

    final body = response.data;
    if (body == null) {
      throw Exception('分片 ${seg.index} 响应体为空');
    }

    final sink = segFile.openWrite(mode: FileMode.append);
    Object? caught;
    try {
      await for (final chunk in body.stream) {
        sink.add(chunk);
        seg.downloaded += chunk.length;
        _aggregateSegmentsProgress(item);
        _persistThrottled(item);
      }
    } catch (e) {
      caught = e;
    } finally {
      try {
        await sink.flush();
      } catch (_) {}
      await sink.close();
    }
    if (caught != null) {
      // 重新抛出以便上层 retry 逻辑识别（cancel / 网络异常）
      throw caught;
    }

    // 校验分片大小
    final actualSize = await segFile.length();
    if (actualSize != seg.expectedSize) {
      throw Exception(
        '分片 ${seg.index} 大小不匹配：期望 ${seg.expectedSize}，实际 $actualSize',
      );
    }
    seg.downloaded = seg.expectedSize;
  }

  void _aggregateSegmentsProgress(DownloadItemModel item) {
    if (item.segments.isEmpty) return;
    var total = 0;
    for (final seg in item.segments) {
      total += seg.downloaded;
    }
    _updateProgress(item, total, item.totalSize);
  }

  Future<void> _mergeSegmentFiles(
    DownloadItemModel item,
    List<SegmentInfo> segments,
  ) async {
    const chunkSize = 65536;
    final destFile = File(item.savePath);
    final parent = destFile.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    final dest = await destFile.open(mode: FileMode.write);
    try {
      for (final seg in segments) {
        final segPath = '${item.savePath}.part${seg.index}';
        final src = await File(segPath).open(mode: FileMode.read);
        try {
          while (true) {
            final chunk = await src.read(chunkSize);
            if (chunk.isEmpty) break;
            await dest.writeFrom(chunk);
          }
        } finally {
          await src.close();
        }
        await File(segPath).delete();
      }
    } finally {
      await dest.close();
    }
  }

  int _segmentCount(int fileSize) {
    if (fileSize < 10 * 1024 * 1024) return 1; // < 10MB: 单线程
    if (fileSize < 100 * 1024 * 1024) return 2; // 10-100MB: 2片
    if (fileSize < 512 * 1024 * 1024) return 4; // 100-512MB: 4片
    if (fileSize < 2 * 1024 * 1024 * 1024) return 8; // 512MB-2GB: 8片
    return 16; // > 2GB: 16片
  }

  List<SegmentInfo> _calculateSegments(int fileSize, int count) {
    final segments = <SegmentInfo>[];
    final segSize = fileSize ~/ count;
    int start = 0;
    for (int i = 0; i < count; i++) {
      final end = (i == count - 1) ? fileSize - 1 : start + segSize - 1;
      segments.add(SegmentInfo(index: i, start: start, end: end));
      start = end + 1;
    }
    return segments;
  }

  // ---------------------------------------------------------------------------
  // URL 刷新 / 远端校验
  // ---------------------------------------------------------------------------

  /// 调用 API 重新获取下载链接（123pan 链接是签名一次性 URL，长任务会过期）。
  /// 外部 URL 任务无对应 API，直接返回 false。
  Future<bool> _refreshDownloadUrl(DownloadItemModel item) async {
    if (item.isExternal) return false;

    final id = item.file.fileId.toString();
    final lastRefresh = _lastRefreshTimes[id];
    if (lastRefresh != null &&
        DateTime.now().difference(lastRefresh) < _kUrlRefreshCooldown) {
      return false;
    }

    try {
      final result = await Get.find<NetSession>().getFileLink(item.file);
      if (result.apiCodeEnum == ApiCode.success) {
        final newUrl = result.data;
        if (newUrl is String && newUrl.isNotEmpty) {
          item.downloadUrl = newUrl;
          _lastRefreshTimes[id] = DateTime.now();
          await _saveDownloadList();
          return true;
        }
      }
    } catch (_) {
      // 网络等异常，按刷新失败处理
    }
    return false;
  }

  /// 续传前用 HEAD 校验远端文件大小 / ETag 与本地记录一致。
  ///
  /// 返回 false 表示文件已变化，调用方应放弃续传。
  /// HEAD 失败（例如服务器不支持 HEAD 或网络错误）按"无法验证"处理，返回 true。
  Future<bool> _verifyRemoteFile(DownloadItemModel item) async {
    try {
      final response = await _dio.head(
        item.downloadUrl,
        options: Options(headers: _headersFor(item)),
      );

      final contentLength = int.tryParse(
        response.headers.value('content-length') ?? '',
      );
      if (contentLength != null &&
          item.totalSize > 0 &&
          contentLength != item.totalSize) {
        item.errorMessage =
            '远端文件大小已变更，远端: $contentLength 字节，本地: ${item.totalSize} 字节';
        return false;
      }

      final remoteEtag = response.headers.value('etag');
      if (item.etag != null &&
          item.etag!.isNotEmpty &&
          remoteEtag != null &&
          remoteEtag.isNotEmpty &&
          remoteEtag != item.etag) {
        item.errorMessage = '远端文件已变更(ETag不匹配)';
        return false;
      }

      // 没有本地 ETag 但远端给出，记录下来供下次校验
      if ((item.etag == null || item.etag!.isEmpty) &&
          remoteEtag != null &&
          remoteEtag.isNotEmpty) {
        item.etag = remoteEtag;
      }

      return true;
    } catch (_) {
      // 无法验证 —— 继续下载，避免误杀
      return true;
    }
  }

  Future<void> _getDownloadInfo(DownloadItemModel item) async {
    try {
      final response = await _dio.head(
        item.downloadUrl,
        options: Options(headers: _headersFor(item)),
      );

      final contentLength = response.headers['content-length']?.first;
      if (contentLength != null) {
        item.totalSize = int.parse(contentLength);
      }

      // 仅当 Accept-Ranges: bytes 时才确认支持断点续传
      final acceptRanges = response.headers['accept-ranges']?.first;
      if (acceptRanges != null && acceptRanges.toLowerCase() == 'bytes') {
        item.supportsResume = true;
      }

      final etag = response.headers['etag']?.first;
      if (etag != null) {
        item.etag = etag;
      }
    } catch (_) {
      // HEAD 请求失败时保持默认值继续下载
    }
  }

  // ---------------------------------------------------------------------------
  // 通用工具
  // ---------------------------------------------------------------------------

  void _updateProgress(DownloadItemModel item, int received, int total) {
    item.downloadedSize = received;
    if (total > 0) item.totalSize = total;
    item.progress = item.totalSize > 0 ? received / item.totalSize : 0;

    final id = item.file.fileId.toString();
    final tracker = _speedTrackers.putIfAbsent(id, () => _SpeedTracker());

    final now = DateTime.now();
    final elapsed = now.difference(tracker.lastTime).inMilliseconds;
    if (elapsed > 800) {
      final bytesDiff = received - tracker.lastBytes;
      item.speed = (bytesDiff ~/ (elapsed / 1000).ceil()).clamp(0, bytesDiff);
      tracker.lastBytes = received;
      tracker.lastTime = now;
    }

    _notifyProgress(item);
  }

  Future<void> _markCompleted(DownloadItemModel item) async {
    item.status = DownloadStatus.completed;
    item.endTime = DateTime.now();
    item.progress = 1.0;
    item.downloadedSize = item.totalSize;
    item.speed = 0;
    item.errorMessage = null;
    _speedTrackers.remove(item.file.fileId.toString());
    _notifyProgress(item);
    await _persistFlush(item);
    _notifyListChange();
  }

  void _handleDownloadError(DownloadItemModel item, Object e) {
    final id = item.file.fileId.toString();
    if (e is DioException && CancelToken.isCancel(e)) {
      item.status = DownloadStatus.paused;
    } else {
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString();
    }
    item.speed = 0;
    _speedTrackers.remove(id);
    _notifyProgress(item);
    _persistFlush(item);
    _notifyListChange();
  }

  /// 删除任务关联的所有临时文件（.tmp 和 .partN）。
  Future<void> _cleanupTaskTempFiles(DownloadItemModel item) async {
    final tmp = File('${item.savePath}.tmp');
    if (await tmp.exists()) {
      try {
        await tmp.delete();
      } catch (_) {}
    }
    // 已知的分片
    for (final seg in item.segments) {
      final p = File('${item.savePath}.part${seg.index}');
      if (await p.exists()) {
        try {
          await p.delete();
        } catch (_) {}
      }
    }
    // 兜底：扫描可能存在的更多分片（如分片数下调过的历史文件）
    for (var i = 0; i < 64; i++) {
      final p = File('${item.savePath}.part$i');
      if (await p.exists()) {
        try {
          await p.delete();
        } catch (_) {}
      } else if (i > item.segments.length) {
        // 连续找不到且超过当前分片数，提前退出
        break;
      }
    }
  }

  void _notifyProgress(DownloadItemModel item) {
    _progressController.add(item);
  }

  void _notifyListChange() {
    _listController.add(List.unmodifiable(_downloadList));
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  @override
  void onClose() {
    pauseAllDownloads();
    for (final t in _persistTimers.values) {
      t.cancel();
    }
    _persistTimers.clear();
    _progressController.close();
    _listController.close();
    super.onClose();
  }
}

class _SpeedTracker {
  int lastBytes = 0;
  DateTime lastTime = DateTime.now();
}
