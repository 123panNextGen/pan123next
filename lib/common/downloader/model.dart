import 'package:pan123next/common/api/model.dart';

enum DownloadStatus {
  pending, // 待下载
  downloading, // 下载中
  paused, // 暂停
  completed, // 完成
  failed, // 失败
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
  bool supportsResume;
  String? etag;

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
    this.supportsResume = false,
    this.etag,
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
      'supportsResume': supportsResume,
      'etag': etag,
    };
  }

  factory DownloadItemModel.fromJson(Map<String, dynamic> json) {
    return DownloadItemModel(
      file: FileItemModel.fromJson(json['file']),
      savePath: json['savePath'],
      downloadUrl: json['downloadUrl'],
      status: DownloadStatus.values[json['status']],
      downloadedSize: json['downloadedSize'],
      totalSize: json['totalSize'],
      progress: json['progress'],
      speed: json['speed'],
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      errorMessage: json['errorMessage'],
      supportsResume: json['supportsResume'] ?? false,
      etag: json['etag'],
    );
  }
}
