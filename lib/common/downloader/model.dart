import 'package:dio/dio.dart';
import 'package:pan123next/common/api/model.dart';

enum DownloadStatus {
  pending, // 待下载
  downloading, // 下载中
  paused, // 暂停
  completed, // 完成
  failed, // 失败
}

/// 单个分片的元信息。
///
/// 字段会随任务一起序列化到 SharedPreferences，因此可以在应用崩溃 / 重启后
/// 从 `downloaded` 字段恢复每个分片的下载进度（断点续传）。
/// `cancelToken` 是运行时字段，不会持久化。
class SegmentInfo {
  final int index;
  final int start; // 起始字节（含）
  final int end; // 结束字节（含）
  int downloaded; // 已成功写入字节数；续传起点 = start + downloaded
  bool completed;

  // 仅运行时使用，不参与序列化
  CancelToken? cancelToken;

  SegmentInfo({
    required this.index,
    required this.start,
    required this.end,
    this.downloaded = 0,
    this.completed = false,
  });

  int get expectedSize => end - start + 1;

  Map<String, dynamic> toJson() => {
    'index': index,
    'start': start,
    'end': end,
    'downloaded': downloaded,
    'completed': completed,
  };

  factory SegmentInfo.fromJson(Map<String, dynamic> json) => SegmentInfo(
    index: json['index'] as int,
    start: json['start'] as int,
    end: json['end'] as int,
    downloaded: (json['downloaded'] ?? 0) as int,
    completed: (json['completed'] ?? false) as bool,
  );
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

  /// 分片列表。空列表表示单线程下载或尚未规划分片。
  /// 每个 [SegmentInfo] 都会持久化，崩溃恢复时直接复用。
  List<SegmentInfo> segments;

  /// 任务级重试次数（当前仅占位，便于未来扩展整体级别的策略）。
  int retryCount;

  /// 是否为外部 URL（非 123pan）。外部任务不附带 123pan 鉴权头，
  /// 也不会在过期时自动刷新 URL。
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
    this.supportsResume = false,
    this.etag,
    List<SegmentInfo>? segments,
    this.retryCount = 0,
    this.isExternal = false,
  }) : segments = segments ?? [];

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
      'segments': segments.map((s) => s.toJson()).toList(),
      'retryCount': retryCount,
      'isExternal': isExternal,
    };
  }

  factory DownloadItemModel.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as List?;
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
      segments: segmentsJson
          ?.map((e) => SegmentInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      retryCount: (json['retryCount'] ?? 0) as int,
      isExternal: (json['isExternal'] ?? false) as bool,
    );
  }
}
