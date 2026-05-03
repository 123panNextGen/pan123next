import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/common/downloader/model.dart';
import 'package:pan123next/common/format.dart';

class TransferTile extends StatefulWidget {
  const TransferTile({super.key, required this.file});

  final DownloadItemModel file;

  @override
  State<TransferTile> createState() => _TransferTileState();
}

class _TransferTileState extends State<TransferTile> {
  final AppSession appSession = Get.find();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        getFileIconDataBySuffix(widget.file.file.fileName.split('.').last),
        color: appSession.accentColor.value,
        size: 24,
      ),
      title: Text(widget.file.file.fileName),
      subtitle: Text(formatSize(widget.file.file.size)),
    );
  }
}
