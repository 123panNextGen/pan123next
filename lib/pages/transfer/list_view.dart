import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:pan123next/common/downloader/downloader.dart';
import 'package:pan123next/common/format.dart';

class DownloadListView extends StatefulWidget {
  const DownloadListView({super.key});

  @override
  State<DownloadListView> createState() => _DownloadListViewState();
}

class _DownloadListViewState extends State<DownloadListView> {
  StreamSubscription<DownloadTask>? _subscription;
  Timer? _refreshTimer;
  final Map<String, _SpeedTracker> _speedTrackers = {};

  @override
  void initState() {
    super.initState();
    final mgr = DownloadManager();
    mgr.init();

    for (final task in mgr.tasks) {
      _speedTrackers[task.id] = _SpeedTracker()..init(task.receivedBytes);
    }

    _subscription = mgr.onTaskUpdated.listen((task) {
      _speedTrackers.putIfAbsent(task.id, () => _SpeedTracker()).update(task.receivedBytes);
      if (mounted) setState(() {});
    });

    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        bool hasActive = DownloadManager().tasks.any(
          (t) => t.status == DownloadStatus.downloading,
        );
        if (hasActive) {
          for (final task in DownloadManager().tasks) {
            _speedTrackers.putIfAbsent(task.id, () => _SpeedTracker())
                .update(task.receivedBytes);
          }
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = DownloadManager().tasks;
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.arrow_download_24_regular,
              size: 48,
              color: FluentTheme.of(context).inactiveColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无下载任务',
              style: FluentTheme.of(context).typography.subtitle,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (_, i) => _buildTaskItem(tasks[i]),
    );
  }

  Widget _buildTaskItem(DownloadTask task) {
    final speed = _speedTrackers[task.id]?.speed ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                getFileIcon(task.file),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.file.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${formatSize(task.receivedBytes)} / ${formatSize(task.totalBytes)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: FluentTheme.of(context).inactiveColor,
                            ),
                          ),
                          if (task.status == DownloadStatus.downloading || speed > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              _formatSpeed(speed),
                              style: TextStyle(
                                fontSize: 12,
                                color: FluentTheme.of(context).inactiveColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(task),
              ],
            ),
            if (task.status == DownloadStatus.downloading ||
                task.status == DownloadStatus.paused) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ProgressBar(value: (task.progress * 100).clamp(0, 100)),
                  ),
                  const SizedBox(width: 10),
                  Text('${(task.progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ],
            if (task.chunkProgress != null && task.chunkProgress!.length > 1) ...[
              const SizedBox(height: 8),
              _buildChunkBars(task),
            ],
            if (task.status == DownloadStatus.failed &&
                task.errorMessage != null &&
                task.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.errorMessage!,
                style: TextStyle(
                  fontSize: 11,
                  color: FluentTheme.of(context).resources.systemFillColorCritical,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.pause_24_regular),
              onPressed: () => DownloadManager().pause(task.id),
            ),
            IconButton(
              icon: const Icon(FluentIcons.delete_24_regular),
              onPressed: () => DownloadManager().remove(task.id),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.play_24_regular),
              onPressed: () => DownloadManager().start(task.id),
            ),
            IconButton(
              icon: const Icon(FluentIcons.delete_24_regular),
              onPressed: () => DownloadManager().remove(task.id),
            ),
          ],
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(FluentIcons.delete_24_regular),
          onPressed: () => DownloadManager().remove(task.id),
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.arrow_repeat_all_24_regular),
              onPressed: () => DownloadManager().retry(task.id),
            ),
            IconButton(
              icon: const Icon(FluentIcons.delete_24_regular),
              onPressed: () => DownloadManager().remove(task.id),
            ),
          ],
        );
      case DownloadStatus.cancelled:
      case DownloadStatus.pending:
        return IconButton(
          icon: const Icon(FluentIcons.delete_24_regular),
          onPressed: () => DownloadManager().remove(task.id),
        );
    }
  }

  Widget _buildChunkBars(DownloadTask task) {
    final chunks = task.chunkProgress!;
    final done = chunks.where((c) => c.progress >= 1.0).length;

    return Expander(
      header: Text(
        '分片 $done/${chunks.length}',
        style: TextStyle(
          fontSize: 12,
          color: FluentTheme.of(context).inactiveColor,
        ),
      ),
      content: Column(
        children: chunks.map((cp) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    '分片 ${cp.index}',
                    style: TextStyle(
                      fontSize: 11,
                      color: FluentTheme.of(context).inactiveColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 8,
                    child: ProgressBar(value: (cp.progress * 100).clamp(0, 100)),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(cp.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: FluentTheme.of(context).inactiveColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    if (bytesPerSec < 1024 * 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSec / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }
}

class _SpeedTracker {
  int _lastBytes = 0;
  DateTime _lastTime = DateTime.now();
  int speed = 0;

  void init(int bytes) {
    _lastBytes = bytes;
    _lastTime = DateTime.now();
    speed = 0;
  }

  void update(int receivedBytes) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastTime).inMilliseconds;
    if (elapsed > 0) {
      final delta = receivedBytes - _lastBytes;
      speed = delta >= 0 ? ((delta / elapsed) * 1000).round() : 0;
    }
    _lastBytes = receivedBytes;
    _lastTime = now;
  }
}
