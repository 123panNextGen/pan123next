import 'package:shared_preferences/shared_preferences.dart';

class DownloaderDb {
  static const _prefix = 'downloader';
  static SharedPreferences? _prefs;

  final Map<String, dynamic> _cache = {};
  bool _initialized = false;

  static final DownloaderDb _instance = DownloaderDb._internal();
  factory DownloaderDb() => _instance;
  DownloaderDb._internal();

  Future<void> initDb() async {
    if (_initialized) return;

    _prefs ??= await SharedPreferences.getInstance();

    final keys = [
      '$_prefix.downloadList',
      '$_prefix.initialed',
    ];

    for (final key in keys) {
      final value = _prefs!.get(key);
      if (value != null) {
        _cache[key] = value;
      }
    }

    if (!(_cache['$_prefix.initialed'] ?? false)) {
      await firstInitDb();
    }

    _initialized = true;
  }

  Future<void> firstInitDb() async {
    await _setStringList('$_prefix.downloadList', []);
    await _setBool('$_prefix.initialed', true);
  }

  Future<void> _setStringList(String key, List<String> value) async {
    _cache[key] = value;
    await _prefs!.setStringList(key, value);
  }

  Future<void> _setBool(String key, bool value) async {
    _cache[key] = value;
    await _prefs!.setBool(key, value);
  }

  dynamic getValue(String key) {
    if (!_initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    return _cache['$_prefix.$key'];
  }

  void setValue(String key, dynamic value, String type) {
    if (!_initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    final realKey = '$_prefix.$key';
    switch (type) {
      case 'bool':
        _cache[realKey] = value;
        _prefs!.setBool(realKey, value);
        break;
      case 'int':
        _cache[realKey] = value;
        _prefs!.setInt(realKey, value);
        break;
      case 'stringList':
        _cache[realKey] = value;
        _prefs!.setStringList(realKey, value);
        break;
      case 'string':
      default:
        _cache[realKey] = value;
        _prefs!.setString(realKey, value);
        break;
    }
  }

  List<String> get downloadList => getValue('downloadList') ?? [];

  set downloadList(List<String> value) {
    _cache['$_prefix.downloadList'] = value;
    _prefs!.setStringList('$_prefix.downloadList', value);
  }
}
