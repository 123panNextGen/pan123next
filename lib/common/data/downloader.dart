import 'package:pan123next/common/data/base_db.dart';

class DownloaderDb extends BaseDb {
  @override
  String get prefix => 'downloader';

  static final DownloaderDb _instance = DownloaderDb._internal();
  factory DownloaderDb() => _instance;
  DownloaderDb._internal();

  @override
  Future<void> firstInitDb() async {
    prefs.setStringList('downloader.downloadList', []);
    prefs.setBool('downloader.initialed', true);
  }
}
