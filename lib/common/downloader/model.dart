import 'package:background_downloader/background_downloader.dart';
import 'package:pan123next/common/api/model.dart';

/// 下载状态映射
enum DownloadStatus {
  pending, // 待下载
  downloading, // 下载中
  paused, // 暂停
  completed, // 完成
  failed, // 失败
  canceled, // 取消
}

/// 将 background_downloader 的 TaskStatus 转换为 DownloadStatus
DownloadStatus _mapTaskStatus(TaskStatus status) {
  switch (status) {
    case TaskStatus.enqueued:
      return DownloadStatus.pending;
    case TaskStatus.running:
      return DownloadStatus.downloading;
    case TaskStatus.paused:
      return DownloadStatus.paused;
    case TaskStatus.complete:
      return DownloadStatus.completed;
    case TaskStatus.failed:
      return DownloadStatus.failed;
    case TaskStatus.canceled:
      return DownloadStatus.canceled;
    case TaskStatus.notFound:
      return DownloadStatus.failed;
    case TaskStatus.waitingToRetry:
      return DownloadStatus.pending;
  }
}

class DownloadItemModel {
  final FileItemModel file;
  String savePath;
  String downloadUrl;

  DownloadStatus status;
  int downloadedSize;
  int totalSize;
  double progress;
  int speed;
  DateTime? startTime;
  DateTime? endTime;
  String? errorMessage;

  /// background_downloader 的任务 ID
  String? taskId;

  /// 是否为外部 URL（非 123pan）
  bool isExternal;

  DownloadItemModel({
    required this.file,
    required this.savePath,
    required this.downloadUrl,
    this.status = DownloadStatus.pending,
    this.downloadedSize = 0,
    this.totalSize = 0,
    this.progress = 0.0,
    this.speed = 0,
    this.startTime,
    this.endTime,
    this.errorMessage,
    this.taskId,
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

  Map<String, dynamic> toJson() {
    return {
      'file': file.toJson(),
      'savePath': savePath,
      'downloadUrl': downloadUrl,
      'status': status.index,
      'downloadedSize': downloadedSize,
      'totalSize': totalSize,
      'progress': progress,
      'speed': speed,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'errorMessage': errorMessage,
      'taskId': taskId,
      'isExternal': isExternal,
    };
  }

  factory DownloadItemModel.fromJson(Map<String, dynamic> json) {
    return DownloadItemModel(
      file: FileItemModel.fromJson(json['file']),
      savePath: json['savePath'],
      downloadUrl: json['downloadUrl'],
      status: DownloadStatus.values[json['status']],
      downloadedSize: json['downloadedSize'] ?? 0,
      totalSize: json['totalSize'] ?? 0,
      progress: json['progress'] ?? 0.0,
      speed: json['speed'] ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      errorMessage: json['errorMessage'],
      taskId: json['taskId'],
      isExternal: (json['isExternal'] ?? false) as bool,
    );
  }

  /// 从 background_downloader 的 TaskStatusUpdate 更新状态
  void updateFromTaskStatus(TaskStatus status, {String? error}) {
    this.status = _mapTaskStatus(status);
    if (status == TaskStatus.complete) {
      endTime = DateTime.now();
      progress = 1.0;
      downloadedSize = totalSize;
    }
    if (error != null) {
      errorMessage = error;
    }
  }

  /// 从 background_downloader 的 TaskProgressUpdate 更新进度
  void updateFromProgress(TaskProgressUpdate update) {
    progress = update.progress;
    if (update.hasExpectedFileSize) {
      totalSize = update.expectedFileSize;
    }
    // 计算已下载大小
    if (progress > 0 && progress < 1 && totalSize > 0) {
      downloadedSize = (progress * totalSize).round();
    }
    // 使用库提供的网络速度（MB/s -> bytes/s）
    if (update.hasNetworkSpeed) {
      speed = (update.networkSpeed * 1024 * 1024).round();
    }
  }
}
