import 'package:pan123next/common/data/base_db.dart';

class DownloaderDb extends BaseDb {
  static const _prefix = 'downloader';

  static final DownloaderDb _instance = DownloaderDb._internal();
  factory DownloaderDb() => _instance;
  DownloaderDb._internal();

  @override
  String get prefix => _prefix;

  @override
  List<String> get keys => [
    '$_prefix.downloadList',
    '$_prefix.initialed',
  ];

  @override
  Future<void> firstInitDb() async {
    setValue('downloadList', <String>[]);
  }

  List<String> get downloadList => getValue('downloadList') ?? <String>[];

  set downloadList(List<String> value) => setValue('downloadList', value);
}
