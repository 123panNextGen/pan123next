import 'package:shared_preferences/shared_preferences.dart';

class DownloaderDb {
  static final DownloaderDb _instance = DownloaderDb._internal();
  factory DownloaderDb() => _instance;
  DownloaderDb._internal();

  SharedPreferences? _prefs;

  Future<void> initDb() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();
    try {
      if (!(_prefs!.getBool('downloader.initialed') ?? false)) _firstInitDb();
    } catch (e) {
      _firstInitDb();
    }
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    return _prefs!;
  }

  void _firstInitDb() {
    prefs.setStringList('downloader.downloadList', []);

    prefs.setBool('downloader.initialed', true);
  }

  dynamic getValue(String key) {
    if (key.isEmpty) return;
    return prefs.get('downloader.$key');
  }

  void setValue(String key, dynamic value, String type) {
    if (key.isEmpty) return;
    String realKey = 'downloader.$key';

    switch (type) {
      case 'string':
        prefs.setString(realKey, value);
        break;
      case 'bool':
        prefs.setBool(realKey, value);
        break;
      case 'int':
        prefs.setInt(realKey, value);
        break;
      default:
        break;
    }
  }
}
