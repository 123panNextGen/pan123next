import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/i18n/i18n.dart';
import 'package:pan123next/common/downloader/model.dart';
import 'package:pan123next/common/downloader/session.dart';
import 'package:pan123next/common/app_session.dart';
import 'package:pan123next/pages/transfer/dialog.dart';
import 'package:pan123next/widgets/downloader_tile.dart';
import 'package:pan123next/widgets/show_info_bar.dart';

class DownloaderPage extends StatefulWidget {
  const DownloaderPage({super.key});

  @override
  State<DownloaderPage> createState() => _DownloaderPageState();
}

class _DownloaderPageState extends State<DownloaderPage> {
  final AppSession appSession = Get.find();
  List<DownloadItemModel> _downloadList = [];
  final List<DownloadItemModel> _uploadList = [];
  StreamSubscription<List<DownloadItemModel>>? _listSubscription;
  StreamSubscription<DownloadItemModel>? _progressSubscription;
  final Set<int> _notifiedCompletedIds = {};

  String _filterType = 'transfer.filter.all'.i;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _downloadList = Get.find<DownloadSession>().downloadList;
    _listSubscription = Get.find<DownloadSession>().listStream.listen((list) {
      if (mounted) {
        setState(() => _downloadList = list);
      }
    });
    _progressSubscription =
        Get.find<DownloadSession>().progressStream.listen((item) {
      if (item.status == DownloadStatus.completed &&
          _notifiedCompletedIds.add(item.file.fileId)) {
        if (!mounted) return;
        showInfoBar(
          context,
          'transfer.complete.title'.i,
          item.file.fileName,
          InfoBarSeverity.success,
        );
      }
    });
  }

  @override
  void dispose() {
    _listSubscription?.cancel();
    _progressSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddDownloadDialog() async {
    final result = await showDialog<AddDownloadResult>(
      context: context,
      builder: (_) => const AddDownloadDialog(),
    );
    if (result == null || !mounted) return;
    try {
      await Get.find<DownloadSession>().addExternalDownload(
        url: result.url,
        savePath: result.savePath,
      );
      if (!mounted) return;
      if (_filterType == 'transfer.filter.uploading'.i) {
        setState(() => _filterType = 'transfer.filter.all'.i);
      }
      showInfoBar(context, 'transfer.added.title'.i, 'transfer.added.message'.i, InfoBarSeverity.success);
    } catch (e) {
      if (!mounted) return;
      showInfoBar(context, 'transfer.add.failed'.i, e.toString(), InfoBarSeverity.error);
    }
  }

  List<DownloadItemModel> get _filteredList {
    final List<DownloadItemModel> base;
    switch (_filterType) {
      case var v when v == 'transfer.filter.downloading'.i:
        base = List.of(_downloadList);
        break;
      case var v when v == 'transfer.filter.uploading'.i:
        base = List.of(_uploadList);
        break;
      default:
        base = [..._downloadList, ..._uploadList];
    }

    base.sort((a, b) {
      final ta = a.startTime;
      final tb = b.startTime;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return ta.compareTo(tb);
    });

    final keyword = _searchController.text.toLowerCase();
    if (keyword.isEmpty) return base;
    return base
        .where((item) => item.file.fileName.toLowerCase().contains(keyword))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'transfer.title'.i,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Row(
                    children: [
                      ComboBox(
                        value: _filterType,
                        items: [
                          ComboBoxItem(value: 'transfer.filter.all'.i, child: Text('transfer.filter.all'.i)),
                          ComboBoxItem(
                            value: 'transfer.filter.downloading'.i,
                            child: Row(
                              children: [
                                const Icon(
                                  FluentIcons.arrow_download_24_regular,
                                ),
                                const SizedBox(width: 5),
                                Text('transfer.filter.downloading'.i),
                              ],
                            ),
                          ),
                          ComboBoxItem(
                            value: 'transfer.filter.uploading'.i,
                            child: Row(
                              children: [
                                const Icon(FluentIcons.arrow_upload_24_regular),
                                const SizedBox(width: 5),
                                Text('transfer.filter.uploading'.i),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _filterType = value);
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      Text('transfer.filter.label'.i),
                      Expanded(
                        child: TextBox(
                          controller: _searchController,
                          placeholder: 'transfer.search.placeholder'.i,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _showAddDownloadDialog,
                        child: Row(
                          children: [
                            Icon(FluentIcons.add_24_regular),
                            const SizedBox(width: 4),
                            Text('transfer.add.download'.i),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (list.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          _filterType == 'transfer.filter.uploading'.i
                              ? 'transfer.empty.uploading'.i
                              : _filterType == 'transfer.filter.downloading'.i
                                  ? 'transfer.empty.downloading'.i
                                  : 'transfer.empty.all'.i,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) =>
                            DownloaderTile(file: list[index]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
