import 'package:pan123next/common/api/model.dart';

enum DownloadStatus { pending, downloading, paused, completed, failed, cancelled }

class ChunkProgress {
  final int index;
  final int start;
  final int end;
  int receivedBytes;

  ChunkProgress({
    required this.index,
    required this.start,
    required this.end,
    this.receivedBytes = 0,
  });

  int get size => end - start + 1;
  double get progress => size > 0 ? receivedBytes / size : 0.0;
}

class DownloadTask {
  final String id;
  final FileItemModel file;
  final String savePath;
  final String downloadUrl;
  final Map<String, String>? headers;
  int totalBytes;
  int receivedBytes;
  DownloadStatus status;
  String? errorMessage;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? completedAt;
  int retryCount;
  List<ChunkProgress>? chunkProgress;

  DownloadTask({
    required this.id,
    required this.file,
    required this.savePath,
    required this.downloadUrl,
    this.headers,
    this.totalBytes = 0,
    this.receivedBytes = 0,
    this.status = DownloadStatus.pending,
    this.errorMessage,
    DateTime? createdAt,
    this.updatedAt,
    this.completedAt,
    this.retryCount = 0,
    this.chunkProgress,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0.0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'file': file.toJson(),
    'savePath': savePath,
    'downloadUrl': downloadUrl,
    if (headers != null) 'headers': headers,
    'totalBytes': totalBytes,
    'receivedBytes': receivedBytes,
    'status': status.name,
    if (errorMessage != null) 'errorMessage': errorMessage,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    'retryCount': retryCount,
  };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
    id: json['id'] as String,
    file: FileItemModel.fromJson(json['file'] as Map<String, dynamic>),
    savePath: json['savePath'] as String,
    downloadUrl: json['downloadUrl'] as String,
    headers: json['headers'] != null
        ? (json['headers'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String))
        : null,
    totalBytes: json['totalBytes'] as int? ?? 0,
    receivedBytes: json['receivedBytes'] as int? ?? 0,
    status: DownloadStatus.values.firstWhere((e) => e.name == json['status']),
    errorMessage: json['errorMessage'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    retryCount: json['retryCount'] as int? ?? 0,
  );
}
