import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:pan123next/common/downloader/model.dart';
import 'package:pan123next/common/downloader/session.dart';
import 'package:pan123next/common/app_session.dart';
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
  StreamSubscription<List<DownloadItemModel>>? _listSubscription;
  StreamSubscription<DownloadItemModel>? _progressSubscription;
  final Set<int> _notifiedCompletedIds = {};

  String _filterType = '全部';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _downloadList = DownloadSession().downloadList;
    _listSubscription = DownloadSession().listStream.listen((list) {
      if (mounted) {
        setState(() => _downloadList = list);
      }
    });
    _progressSubscription = DownloadSession().progressStream.listen((item) {
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

  List<DownloadItemModel> get _filteredList {
    return _downloadList.where((item) {
      if (_filterType == '下载' && item.status == DownloadStatus.completed) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        return item.file.fileName.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }
      return true;
    }).toList();
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
                        onPressed: () {},
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
                    const Expanded(child: Center(child: Text('暂无下载任务')))
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
