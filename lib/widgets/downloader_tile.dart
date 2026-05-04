import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/downloader/model.dart';
import 'package:pan123next/common/downloader/session.dart';
import 'package:pan123next/common/format.dart';

class DownloaderTile extends StatefulWidget {
  const DownloaderTile({super.key, required this.file});

  final DownloadItemModel file;

  @override
  State<DownloaderTile> createState() => _DownloaderTileState();
}

class _DownloaderTileState extends State<DownloaderTile> {
  final AppSession appSession = Get.find();
  StreamSubscription<DownloadItemModel>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _progressSubscription = DownloadSession().progressStream.listen((item) {
      if (item.file.fileId == widget.file.file.fileId && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.arrow_download_24_regular,
            color: appSession.accentColor.value,
            size: 24,
          ),
          const SizedBox(width: 5),
          Icon(
            getFileIconDataBySuffix(
              file.savePath.split('/').last.split('.').lastOrNull ?? '',
            ),
            color: appSession.accentColor.value,
            size: 24,
          ),
        ],
      ),
      title: Text(file.savePath.split('/').last),
      subtitle: Row(
        children: [
          Expanded(child: ProgressBar(value: file.progress * 100)),
          const SizedBox(width: 5),
          Text('${(file.progress * 100).toStringAsFixed(0)}%'),
          if (file.status == DownloadStatus.downloading) ...[
            const SizedBox(width: 5),
            Text(file.formattedSpeed),
          ],
          const SizedBox(width: 5),
          Text(
            widget.file.status != DownloadStatus.completed
                ? '${file.formattedDownloadedSize}/${file.formattedTotalSize}'
                : file.formattedTotalSize,
            style: TextStyle(color: Colors.grey[90], fontSize: 12),
          ),
          const SizedBox(width: 5),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (file.status == DownloadStatus.downloading)
            IconButton(
              icon: Icon(FluentIcons.pause_24_regular),
              onPressed: () => DownloadSession().pauseDownload(file),
            ),
          if (file.status == DownloadStatus.paused ||
              file.status == DownloadStatus.failed)
            IconButton(
              icon: Icon(FluentIcons.play_24_regular),
              onPressed: () => DownloadSession().startDownload(file),
            ),
          IconButton(
            icon: Icon(FluentIcons.dismiss_24_regular),
            onPressed: () => DownloadSession().removeDownload(file),
          ),
          IconButton(
            icon: Icon(FluentIcons.more_vertical_24_regular),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
