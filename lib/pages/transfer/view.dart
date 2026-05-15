import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
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

  String _filterType = '全部';
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
          '下载完成',
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
      if (_filterType == '上传') {
        setState(() => _filterType = '全部');
      }
      showInfoBar(context, '已添加', '下载任务已开始', InfoBarSeverity.success);
    } catch (e) {
      if (!mounted) return;
      showInfoBar(context, '添加失败', e.toString(), InfoBarSeverity.error);
    }
  }

  List<DownloadItemModel> get _filteredList {
    final List<DownloadItemModel> base;
    switch (_filterType) {
      case '下载':
        base = List.of(_downloadList);
        break;
      case '上传':
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
          const Text(
            '传输',
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
                          ComboBoxItem(value: '全部', child: Text('全部')),
                          ComboBoxItem(
                            value: '下载',
                            child: Row(
                              children: [
                                const Icon(
                                  FluentIcons.arrow_download_24_regular,
                                ),
                                const SizedBox(width: 5),
                                Text('下载'),
                              ],
                            ),
                          ),
                          ComboBoxItem(
                            value: '上传',
                            child: Row(
                              children: [
                                const Icon(FluentIcons.arrow_upload_24_regular),
                                const SizedBox(width: 5),
                                Text('上传'),
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
                      const Text('过滤: '),
                      Expanded(
                        child: TextBox(
                          controller: _searchController,
                          placeholder: '文件名',
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
                            Text('添加新下载'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (list.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          _filterType == '上传'
                              ? '暂无上传任务'
                              : _filterType == '下载'
                                  ? '暂无下载任务'
                                  : '暂无任务',
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
