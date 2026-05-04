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
  final Map<String, CancelToken> _cancelTokens = {};
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

    if (item.downloadedSize > 0 && item.supportsResume) {
      await _resumeDownload(item);
    } else {
      await _startNewDownload(item);
    }
  }

  Future<void> _startNewDownload(DownloadItemModel item) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.file.fileId.toString()] = cancelToken;

    try {
      await _getDownloadInfo(item);

      final file = File(item.savePath);
      await file.create(recursive: true);

      await _dio.download(
        item.downloadUrl,
        item.savePath,
        options: Options(
          headers: {...headers, 'range': 'bytes=0-'},
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          _updateProgress(item, received, total);
        },
      );

      item.status = DownloadStatus.completed;
      item.endTime = DateTime.now();
      item.progress = 1.0;
      item.downloadedSize = item.totalSize;

      _speedTrackers.remove(item.file.fileId.toString());
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        item.status = DownloadStatus.paused;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.toString();
      }
      _speedTrackers.remove(item.file.fileId.toString());
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } finally {
      _cancelTokens.remove(item.file.fileId.toString());
    }
  }

  Future<void> _resumeDownload(DownloadItemModel item) async {
    final cancelToken = CancelToken();
    _cancelTokens[item.file.fileId.toString()] = cancelToken;

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

      await _dio.download(
        item.downloadUrl,
        item.savePath,
        options: Options(
          headers: {...headers, 'range': 'bytes=${item.downloadedSize}-'},
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          _updateProgress(item, item.downloadedSize + received, item.totalSize);
        },
      );

      item.status = DownloadStatus.completed;
      item.endTime = DateTime.now();
      item.progress = 1.0;
      item.downloadedSize = item.totalSize;

      _speedTrackers.remove(item.file.fileId.toString());
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        item.status = DownloadStatus.paused;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.toString();
      }
      _speedTrackers.remove(item.file.fileId.toString());
      _notifyProgress(item);
      await _saveDownloadList();
      _notifyListChange();
    } finally {
      _cancelTokens.remove(item.file.fileId.toString());
    }
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

      final etag = response.headers['etag']?.first;
      if (etag != null) {
        item.etag = etag;
        item.supportsResume = true;
      }

      final acceptRanges = response.headers['accept-ranges']?.first;
      if (acceptRanges != null && acceptRanges.toLowerCase() == 'bytes') {
        item.supportsResume = true;
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
    final tracker =
        _speedTrackers.putIfAbsent(id, () => _SpeedTracker());

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
    _cancelTokens[id]?.cancel();
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
