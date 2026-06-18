import 'package:pan123next/common/api/model.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  canceled,
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

  int? get remainingSeconds => null;

  String get formattedTotalSize => '';
  String get formattedDownloadedSize => '';
  String get formattedSpeed => '';

  static DownloadItemModel? fromServerMap(Map<String, dynamic> map) => null;

  void updateFromServerMap(Map<String, dynamic> map) {}

  void updateProgressFromMap(Map<String, dynamic> map) {}

  void markCompleted() {}

  void markFailed(String? error) {}

  void updateProgress(int bytesReceived, int totalBytes) {}

  void updateSpeed(int bytesPerSecond) {}
}
