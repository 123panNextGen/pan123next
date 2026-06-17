import 'package:pan123next/common/api/model.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  canceled,
}

DownloadStatus _statusFromString(String s) {
  switch (s) {
    case 'pending':
      return DownloadStatus.pending;
    case 'downloading':
      return DownloadStatus.downloading;
    case 'paused':
      return DownloadStatus.paused;
    case 'completed':
      return DownloadStatus.completed;
    case 'failed':
      return DownloadStatus.failed;
    default:
      return DownloadStatus.pending;
  }
}

class DownloadItemModel {
  final FileItemModel file;
  String savePath;
  String downloadUrl;
  String taskId;

  DownloadStatus status;
  int downloadedSize;
  int totalSize;
  double progress;
  int speed;
  DateTime? startTime;
  DateTime? endTime;
  String? errorMessage;
  bool isExternal;

  DownloadItemModel({
    required this.file,
    required this.savePath,
    required this.downloadUrl,
    this.taskId = '',
    this.status = DownloadStatus.pending,
    this.downloadedSize = 0,
    this.totalSize = 0,
    this.progress = 0.0,
    this.speed = 0,
    this.startTime,
    this.endTime,
    this.errorMessage,
    this.isExternal = false,
  });

  int? get remainingSeconds {
    if (status != DownloadStatus.downloading || speed == 0) return null;
    final remaining = totalSize - downloadedSize;
    return (remaining / speed).ceil();
  }

  String get formattedTotalSize => _formatSize(totalSize);
  String get formattedDownloadedSize => _formatSize(downloadedSize);
  String get formattedSpeed => '${_formatSize(speed)}/s';

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ---------------------------------------------------------------------------
  // Go 后端数据映射
  // ---------------------------------------------------------------------------

  static DownloadItemModel? fromServerMap(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final url = map['url'] as String? ?? '';
    final savePath = map['save_path'] as String? ?? '';
    final fileName = map['file_name'] as String? ?? '未知文件';
    final totalSize = _toInt(map['total_size']);
    final downloaded = _toInt(map['downloaded']);
    final status = _statusFromString(map['status'] as String? ?? '');
    final speed = _toInt(map['speed']);
    final errorMsg = map['error_message'] as String?;

    if (id == null || id.isEmpty) return null;

    final fileItem = FileItemModel(
      fileId: id.hashCode,
      fileName: fileName,
      type: 0,
      size: totalSize,
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

    final item = DownloadItemModel(
      file: fileItem,
      savePath: savePath,
      downloadUrl: url,
      taskId: id,
      status: status,
      downloadedSize: downloaded,
      totalSize: totalSize,
      speed: speed,
      errorMessage: errorMsg,
    );

    if (totalSize > 0) {
      item.progress = downloaded / totalSize;
    }

    return item;
  }

  void updateFromServerMap(Map<String, dynamic> map) {
    totalSize = _toInt(map['total_size']);
    downloadedSize = _toInt(map['downloaded']);
    speed = _toInt(map['speed']);
    errorMessage = map['error_message'] as String?;
    status = _statusFromString(map['status'] as String? ?? '');

    if (totalSize > 0) {
      progress = downloadedSize / totalSize;
    }
  }

  /// 只更新进度字段，不覆盖 status（用于 pending 操作期间避免状态回退）。
  void updateProgressFromMap(Map<String, dynamic> map) {
    totalSize = _toInt(map['total_size']);
    downloadedSize = _toInt(map['downloaded']);
    speed = _toInt(map['speed']);
    errorMessage = map['error_message'] as String?;

    if (totalSize > 0) {
      progress = downloadedSize / totalSize;
    }
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // 序列化（用于旧版持久化，后续可移除）
  // ---------------------------------------------------------------------------

  void markCompleted() {
    status = DownloadStatus.completed;
    endTime = DateTime.now();
    progress = 1.0;
    downloadedSize = totalSize;
  }

  void markFailed(String? error) {
    status = DownloadStatus.failed;
    errorMessage = error;
    speed = 0;
  }

  void updateProgress(int bytesReceived, int totalBytes) {
    downloadedSize = bytesReceived;
    totalSize = totalBytes;
    progress = totalBytes > 0 ? bytesReceived / totalBytes : 0.0;
  }

  void updateSpeed(int bytesPerSecond) {
    speed = bytesPerSecond;
  }
}
