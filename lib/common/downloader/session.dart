import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pan123next/common/api/model.dart';
import 'package:pan123next/common/data/downloader.dart';
import 'model.dart';

class DownloadSession {
  static final DownloadSession _instance = DownloadSession._internal();
  factory DownloadSession() => _instance;
  DownloadSession._internal();

  late final Dio _dio;
  Map<String, dynamic> headers = {};
  UserInfoModel? _userInformation;

  final List<DownloadItemModel> _downloadList = [];
  final Map<String, List<CancelToken>> _cancelTokens = {};
  final Map<String, List<_SegmentInfo>> _segments = {};
  final Map<String, _SpeedTracker> _speedTrackers = {};
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

  void _updateHeaders() {
    if (_userInformation == null) return;

    headers = {
      'user-agent': '123pan/v2.4.0(${_userInformation!.device.os};Xiaomi)',
      'authorization': _userInformation!.authorization,
      'accept-encoding': 'gzip',
      'content-type': 'application/json',
      'osversion': _userInformation!.device.os,
      'loginuuid': _userInformation!.uuid,
      'platform': 'android',
      'devicetype': _userInformation!.device.type,
      'devicename': 'Xiaomi',
      'host': 'www.123pan.com',
      'app-version': '61',
      'x-app-version': '2.4.0',
    };
  }

  Future<void> _loadDownloadList() async {
    final db = DownloaderDb();
    final List<dynamic> listJson = db.getValue('downloadList') ?? [];

    _downloadList.clear();
    for (final jsonStr in listJson) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final item = DownloadItemModel.fromJson(jsonMap);

        final file = File(item.savePath);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (item.status == DownloadStatus.downloading) {
            item.status = DownloadStatus.paused;
          }
          if (fileSize != item.downloadedSize) {
            item.downloadedSize = fileSize;
            item.progress = item.totalSize > 0
                ? item.downloadedSize / item.totalSize
                : 0;
          }
          _downloadList.add(item);
        }
      } catch (_) {
        // 跳过已损坏的条目，不影响其他记录加载
      }
    }
    _notifyListChange();
  }

  Future<void> _saveDownloadList() async {
    final db = DownloaderDb();
    final listJson = _downloadList
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    db.prefs.setStringList('downloader.downloadList', listJson);
  }

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

  Future<void> startDownload(DownloadItemModel item) async {
    await _ensureInitialized();

    if (item.status == DownloadStatus.downloading) return;

    item.status = DownloadStatus.downloading;
    item.startTime = DateTime.now();
    await _saveDownloadList();
    _notifyProgress(item);

    if (item.downloadedSize > 0) {
      await _resumeDownload(item);
    } else {
      await _startNewDownload(item);
    }
  }

  Future<void> _startNewDownload(DownloadItemModel item) async {
    final id = item.file.fileId.toString();

    try {
      await _getDownloadInfo(item);

      if (item.totalSize <= 0) {
        item.status = DownloadStatus.failed;
        item.errorMessage = '无法获取文件大小';
        _notifyProgress(item);
        await _saveDownloadList();
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
            headers: headers,
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(seconds: 300),
          ),
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            _updateProgress(item, received, total);
          },
        );
      } else {
        // 大文件，分片并行下载
        await _segmentedDownload(item, segCount);
      }

      item.status = DownloadStatus.completed;
      item.endTime = DateTime.now();
      item.progress = 1.0;
      item.downloadedSize = item.totalSize;

      _speedTrackers.remove(id);
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } catch (e) {
      _cancelTokens.remove(id);
      _segments.remove(id);
      if (e is DioException && e.type == DioExceptionType.cancel) {
        item.status = DownloadStatus.paused;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.toString();
      }
      _speedTrackers.remove(id);
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } finally {
      _cancelTokens.remove(id);
      _segments.remove(id);
    }
  }

  Future<void> _resumeDownload(DownloadItemModel item) async {
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
          headers: {...headers, 'range': 'bytes=${item.downloadedSize}-'},
          receiveTimeout: const Duration(seconds: 300),
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          _updateProgress(item, item.downloadedSize + received, item.totalSize);
        },
      );

      final statusCode = response.statusCode ?? 0;
      final tempSize = await tempFile.length();

      if (statusCode == 200) {
        // 服务器忽略 Range 返回完整文件，直接替换
        await tempFile.rename(item.savePath);
        item.downloadedSize = tempSize;
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
        item.errorMessage = '断点续传失败：HTTP $statusCode';
        _speedTrackers.remove(id);
        _notifyProgress(item);
        await _saveDownloadList();
        _notifyListChange();
        return;
      }

      // 验证文件完整性
      final finalSize = await file.length();
      if (finalSize < item.totalSize) {
        item.status = DownloadStatus.failed;
        item.errorMessage = '下载不完整：$finalSize / ${item.totalSize}';
      } else {
        item.status = DownloadStatus.completed;
        item.endTime = DateTime.now();
        item.progress = 1.0;
        item.downloadedSize = item.totalSize;
      }

      _speedTrackers.remove(id);
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } catch (e) {
      // 清理临时文件
      final tempFile = File('${item.savePath}.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      if (e is DioException && e.type == DioExceptionType.cancel) {
        item.status = DownloadStatus.paused;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.toString();
      }
      _speedTrackers.remove(id);
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } finally {
      _cancelTokens.remove(id);
    }
  }

  Future<void> _segmentedDownload(DownloadItemModel item, int segCount) async {
    final id = item.file.fileId.toString();
    final segments = _calculateSegments(item.totalSize, segCount);
    _segments[id] = segments;

    final cancelTokens = <CancelToken>[];
    final futures = <Future<void>>[];
    final errors = <Object>[];

    for (final seg in segments) {
      final token = CancelToken();
      seg.cancelToken = token;
      cancelTokens.add(token);
      _cancelTokens.putIfAbsent(id, () => []).add(token);

      final segPath = '${item.savePath}.part${seg.index}';
      futures.add(_downloadSegment(item, seg, segPath));
    }

    // 等待所有分片完成
    for (int i = 0; i < futures.length; i++) {
      try {
        await futures[i];
      } catch (e) {
        errors.add(e);
        // 取消其他未完成的片，并等待其确认（防止 Future 异常漏捕）
        for (int j = i + 1; j < futures.length; j++) {
          cancelTokens[j].cancel();
        }
        for (int j = i + 1; j < futures.length; j++) {
          try {
            await futures[j];
          } catch (_) {
            // 被取消的分片必然抛 cancel 异常，吞掉即可
          }
        }
        break;
      }
    }

    if (errors.isNotEmpty) {
      // 清理分片文件
      for (final seg in segments) {
        final p = File('${item.savePath}.part${seg.index}');
        if (await p.exists()) await p.delete();
      }
      throw errors.first;
    }

    // 合并分片到最终文件
    await _mergeSegmentFiles(item, segments);
  }

  Future<void> _downloadSegment(
    DownloadItemModel item,
    _SegmentInfo seg,
    String segPath,
  ) async {
    final segFile = File(segPath);
    if (await segFile.exists()) {
      await segFile.delete();
    }
    await segFile.create(recursive: true);

    await _dio.download(
      item.downloadUrl,
      segPath,
      options: Options(
        headers: {
          ...headers,
          'range': 'bytes=${seg.start}-${seg.end}',
        },
        responseType: ResponseType.stream,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 300),
      ),
      cancelToken: seg.cancelToken,
      onReceiveProgress: (received, total) {
        seg.downloaded = received;
        _aggregateSegmentsProgress(item, item.file.fileId.toString());
      },
    );

    // 验证分片大小
    final actualSize = await segFile.length();
    final expectedSize = seg.end - seg.start + 1;
    if (actualSize != expectedSize) {
      throw Exception(
        '分片 ${seg.index} 大小不匹配：期望 $expectedSize，实际 $actualSize',
      );
    }
  }

  void _aggregateSegmentsProgress(DownloadItemModel item, String id) {
    final segments = _segments[id];
    if (segments == null || segments.isEmpty) return;

    int totalDownloaded = 0;
    for (final seg in segments) {
      totalDownloaded += seg.downloaded;
    }
    _updateProgress(item, totalDownloaded, item.totalSize);
  }

  Future<void> _mergeSegmentFiles(
    DownloadItemModel item,
    List<_SegmentInfo> segments,
  ) async {
    const chunkSize = 65536;
    final dest = await File(item.savePath).open(mode: FileMode.write);
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
    if (fileSize < 10 * 1024 * 1024) return 1;          // < 10MB: 单线程
    if (fileSize < 100 * 1024 * 1024) return 2;          // 10-100MB: 2片
    if (fileSize < 512 * 1024 * 1024) return 4;          // 100-512MB: 4片
    if (fileSize < 2 * 1024 * 1024 * 1024) return 8;     // 512MB-2GB: 8片
    return 16;                                            // > 2GB: 16片
  }

  List<_SegmentInfo> _calculateSegments(int fileSize, int count) {
    final segments = <_SegmentInfo>[];
    final segSize = fileSize ~/ count;
    int start = 0;

    for (int i = 0; i < count; i++) {
      final end = (i == count - 1) ? fileSize - 1 : start + segSize - 1;
      segments.add(_SegmentInfo(index: i, start: start, end: end));
      start = end + 1;
    }
    return segments;
  }

  Future<void> _getDownloadInfo(DownloadItemModel item) async {
    try {
      final response = await _dio.head(
        item.downloadUrl,
        options: Options(headers: headers),
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

  void _updateProgress(DownloadItemModel item, int received, int total) {
    item.downloadedSize = received;
    item.totalSize = total;
    item.progress = total > 0 ? received / total : 0;

    final id = item.file.fileId.toString();
    final tracker = _speedTrackers.putIfAbsent(id, () => _SpeedTracker());

    final now = DateTime.now();
    final elapsed = now.difference(tracker.lastTime).inMilliseconds;
    if (elapsed > 800) {
      final bytesDiff = received - tracker.lastBytes;
      item.speed = bytesDiff ~/ (elapsed / 1000).ceil();
      tracker.lastBytes = received;
      tracker.lastTime = now;
    }

    _notifyProgress(item);
  }

  void pauseDownload(DownloadItemModel item) {
    final id = item.file.fileId.toString();
    final tokens = _cancelTokens[id];
    if (tokens != null) {
      for (final token in tokens) {
        token.cancel();
      }
    }
    _speedTrackers.remove(id);
    item.status = DownloadStatus.paused;
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

  void removeDownload(DownloadItemModel item) {
    pauseDownload(item);
    _downloadList.remove(item);
    _saveDownloadList();
    _notifyListChange();
  }

  void clearCompleted() {
    _downloadList.removeWhere(
      (item) => item.status == DownloadStatus.completed,
    );
    _saveDownloadList();
    _notifyListChange();
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

  void dispose() {
    pauseAllDownloads();
    _progressController.close();
    _listController.close();
  }
}

class _SpeedTracker {
  int lastBytes = 0;
  DateTime lastTime = DateTime.now();
}

class _SegmentInfo {
  final int index;
  final int start;
  final int end;
  int downloaded = 0;
  CancelToken? cancelToken;

  _SegmentInfo({
    required this.index,
    required this.start,
    required this.end,
  });
}
