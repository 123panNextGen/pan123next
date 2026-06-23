import 'dart:io';
import 'dart:math';
import 'package:pan123next/common/downloader/download_task.dart';
import 'package:pan123next/common/downloader/download_config.dart';

class CancelToken {
  bool _cancelled = false;
  void cancel() => _cancelled = true;
  bool get isCancelled => _cancelled;
}

class CancelException implements Exception {
  final String message;
  CancelException([this.message = 'Download cancelled']);
  @override
  String toString() => message;
}

class PauseToken {
  bool _paused = false;
  void requestPause() => _paused = true;
  bool get isPaused => _paused;
}

class PauseException implements Exception {
  final String message;
  PauseException([this.message = 'Download paused']);
  @override
  String toString() => message;
}

typedef DownloadProgressCallback = void Function(int received, int total);
typedef ChunkProgressCallback = void Function(int chunkIndex, int received, int size);

class DownloadEngine {
  final DownloadConfig config;
  static const Duration _minProgressInterval = Duration(milliseconds: 200);

  DownloadEngine({DownloadConfig? config}) : config = config ?? DownloadConfig();

  Future<void> execute({
    required DownloadTask task,
    DownloadProgressCallback? onProgress,
    ChunkProgressCallback? onChunkProgress,
    CancelToken? cancelToken,
    PauseToken? pauseToken,
  }) async {
    final useChunked = task.totalBytes > config.singleStreamThreshold;

    if (useChunked) {
      try {
        await _executeChunked(
          url: task.downloadUrl,
          savePath: task.savePath,
          totalBytes: task.totalBytes,
          headers: task.headers,
          onProgress: onProgress,
          onChunkProgress: onChunkProgress,
          cancelToken: cancelToken,
          pauseToken: pauseToken,
        );
      } on CancelException {
        rethrow;
      } on PauseException {
        rethrow;
      } catch (_) {
        task.chunkProgress = null;
        await _executeSingleStream(
          url: task.downloadUrl,
          savePath: task.savePath,
          totalBytes: task.totalBytes,
          startOffset: task.receivedBytes,
          headers: task.headers,
          onProgress: onProgress,
          cancelToken: cancelToken,
          pauseToken: pauseToken,
        );
      }
    } else {
      await _executeSingleStream(
        url: task.downloadUrl,
        savePath: task.savePath,
        totalBytes: task.totalBytes,
        startOffset: task.receivedBytes,
        headers: task.headers,
        onProgress: onProgress,
        cancelToken: cancelToken,
        pauseToken: pauseToken,
      );
    }
  }

  Future<void> _executeSingleStream({
    required String url,
    required String savePath,
    required int totalBytes,
    int startOffset = 0,
    Map<String, String>? headers,
    DownloadProgressCallback? onProgress,
    CancelToken? cancelToken,
    PauseToken? pauseToken,
  }) async {
    final tmpPath = '$savePath.pan123';

    if (startOffset > 0) {
      final tmpFile = File(tmpPath);
      if (await tmpFile.exists()) {
        final existing = await tmpFile.length();
        if (existing == totalBytes) {
          await tmpFile.rename(savePath);
          return;
        }
        startOffset = existing;
      }
    }

    final tmpFile = File(tmpPath);
    for (int attempt = 0; attempt < config.maxRetries; attempt++) {
      cancelToken?.throwIfCancelled();
      if (pauseToken?.isPaused ?? false) throw PauseException();
      final client = HttpClient()..autoUncompress = true;
      try {
        final request = await client.getUrl(Uri.parse(url));
        if (startOffset > 0) {
          request.headers.set('Range', 'bytes=$startOffset-');
        }
        _applyHeaders(request, headers);

        final response = await request.close();
        if (response.statusCode == 200 || response.statusCode == 206) {
          final raf = await tmpFile.open(mode: FileMode.append);
          try {
            int received = startOffset;
            var lastReport = DateTime.now();
            await for (final chunk in response) {
              cancelToken?.throwIfCancelled();
              if (pauseToken?.isPaused ?? false) throw PauseException();
              raf.writeFromSync(chunk);
              received += chunk.length;
              final now = DateTime.now();
              if (now.difference(lastReport) >= _minProgressInterval) {
                onProgress?.call(received, totalBytes);
                lastReport = now;
              }
            }
            onProgress?.call(received, totalBytes);
          } finally {
            await raf.close();
          }

          await tmpFile.rename(savePath);
          return;
        }
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      } on CancelException {
        rethrow;
      } on PauseException {
        rethrow;
      } on HttpException {
        rethrow;
      } catch (e) {
        if (attempt == config.maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: min(1 << attempt, 30)));
      } finally {
        client.close(force: true);
      }
    }
  }

  Future<void> _executeChunked({
    required String url,
    required String savePath,
    required int totalBytes,
    Map<String, String>? headers,
    required DownloadProgressCallback? onProgress,
    ChunkProgressCallback? onChunkProgress,
    CancelToken? cancelToken,
    PauseToken? pauseToken,
  }) async {
    final tmpDir = Directory('$savePath.pan123');
    if (!await tmpDir.exists()) {
      await tmpDir.create(recursive: true);
    }

    final chunks = <_ChunkInfo>[];
    int offset = 0;
    int chunkIndex = 0;
    while (offset < totalBytes) {
      final end = min(offset + config.chunkSize - 1, totalBytes - 1);
      chunks.add(_ChunkInfo(
        index: chunkIndex,
        start: offset,
        end: end,
        path: '${tmpDir.path}${Platform.pathSeparator}chunk_${chunkIndex.toString().padLeft(4, '0')}',
      ));
      offset = end + 1;
      chunkIndex++;
    }

    int completedBytes = 0;
    for (final chunk in chunks) {
      final chunkFile = File(chunk.path);
      if (await chunkFile.exists()) {
        final len = await chunkFile.length();
        if (len == chunk.size) {
          completedBytes += len;
          onChunkProgress?.call(chunk.index, chunk.size, chunk.size);
        } else {
          onChunkProgress?.call(chunk.index, 0, chunk.size);
        }
      } else {
        onChunkProgress?.call(chunk.index, 0, chunk.size);
      }
    }
    onProgress?.call(completedBytes, totalBytes);

    if (completedBytes == totalBytes) {
      await _mergeChunks(chunks, savePath, tmpDir);
      return;
    }

    final pendingChunks = <_ChunkInfo>[];
    for (final chunk in chunks) {
      final chunkFile = File(chunk.path);
      if (await chunkFile.exists()) {
        final len = await chunkFile.length();
        if (len != chunk.size) {
          pendingChunks.add(chunk);
        }
      } else {
        pendingChunks.add(chunk);
      }
    }

    int globalIndex = 0;

    Future<void> worker() async {
      while (true) {
        cancelToken?.throwIfCancelled();
        if (pauseToken?.isPaused ?? false) throw PauseException();

        _ChunkInfo? chunk;
        if (globalIndex < pendingChunks.length) {
          chunk = pendingChunks[globalIndex++];
        }

        if (chunk == null) break;

        for (int attempt = 0; attempt < config.maxRetries; attempt++) {
          cancelToken?.throwIfCancelled();
          if (pauseToken?.isPaused ?? false) throw PauseException();
          try {
            await _downloadChunk(url, chunk, headers, cancelToken, pauseToken, onChunkProgress);
            completedBytes += chunk.size;
            onProgress?.call(completedBytes, totalBytes);
            onChunkProgress?.call(chunk.index, chunk.size, chunk.size);
            break;
          } on CancelException {
            rethrow;
          } on PauseException {
            rethrow;
          } catch (e) {
            if (attempt == config.maxRetries - 1) rethrow;
            await Future.delayed(Duration(seconds: min(1 << attempt, 30)));
          }
        }
      }
    }

    final workerCount = min(config.maxConcurrentChunks, pendingChunks.length);
    if (workerCount > 0) {
      try {
        await Future.wait(List.generate(workerCount, (_) => worker()));
      } on CancelException {
        await tmpDir.delete(recursive: true);
        rethrow;
      } on PauseException {
        rethrow;
      } catch (e) {
        await tmpDir.delete(recursive: true);
        rethrow;
      }
    }

    cancelToken?.throwIfCancelled();
    if (pauseToken?.isPaused ?? false) throw PauseException();
    await _mergeChunks(chunks, savePath, tmpDir);
  }

  Future<void> _downloadChunk(
    String url,
    _ChunkInfo chunk,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    PauseToken? pauseToken,
    ChunkProgressCallback? onChunkProgress,
  ) async {
    final client = HttpClient()..autoUncompress = true;
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('Range', 'bytes=${chunk.start}-${chunk.end}');
      _applyHeaders(request, headers);

      final response = await request.close();
      if (response.statusCode == 200 || response.statusCode == 206) {
        final file = File(chunk.path);
        await file.create(recursive: true);
        final sink = file.openWrite();
        try {
          int receivedInChunk = 0;
          var lastReport = DateTime.now();
          await for (final data in response) {
            cancelToken?.throwIfCancelled();
            if (pauseToken?.isPaused ?? false) throw PauseException();
            sink.add(data);
            receivedInChunk += data.length;
            final now = DateTime.now();
            if (now.difference(lastReport) >= _minProgressInterval) {
              onChunkProgress?.call(chunk.index, receivedInChunk, chunk.size);
              lastReport = now;
            }
          }
          onChunkProgress?.call(chunk.index, receivedInChunk, chunk.size);
        } finally {
          await sink.close();
        }
        return;
      }
      throw HttpException('Chunk HTTP ${response.statusCode}', uri: Uri.parse(url));
    } on CancelException {
      rethrow;
    } on PauseException {
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _mergeChunks(List<_ChunkInfo> chunks, String savePath, Directory tmpDir) async {
    final outputFile = File(savePath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }
    await outputFile.create(recursive: true);
    final sink = outputFile.openWrite();
    try {
      for (final chunk in chunks) {
        final chunkFile = File(chunk.path);
        await sink.addStream(chunkFile.openRead());
        await chunkFile.delete();
      }
    } finally {
      await sink.close();
    }

    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  }

  void _applyHeaders(HttpClientRequest request, Map<String, String>? headers) {
    if (headers == null) return;
    for (final entry in headers.entries) {
      final lower = entry.key.toLowerCase();
      if (lower == 'range' || lower == 'content-type' || lower == 'content-length') continue;
      request.headers.set(entry.key, entry.value);
    }
  }
}

class _ChunkInfo {
  final int index;
  final int start;
  final int end;
  final String path;
  _ChunkInfo({required this.index, required this.start, required this.end, required this.path});
  int get size => end - start + 1;
}

extension on CancelToken {
  void throwIfCancelled() {
    if (isCancelled) throw CancelException();
  }
}
