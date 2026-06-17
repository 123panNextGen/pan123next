import 'package:pan123next/common/data/base_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloaderDb extends BaseDb {
  static const _prefix = 'downloader';
  static SharedPreferences? _prefs;

  final Map<String, dynamic> _cache = {};
  bool _initialized = false;

  static final DownloaderDb _instance = DownloaderDb._internal();
  factory DownloaderDb() => _instance;
  DownloaderDb._internal();

  @override
  String get prefix => _prefix;

  @override
  Future<void> initDb() async {
    if (_initialized) return;

    _prefs ??= await SharedPreferences.getInstance();

    final keys = ['$_prefix.downloadList', '$_prefix.initialed'];

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

  @override
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

  @override
  dynamic getValue(String key) {
    if (!_initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    return _cache['$_prefix.$key'];
  }

  @override
  void setValue<T>(String key, T value) {
    if (!_initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    final realKey = '$_prefix.$key';
    if (value is String) {
      prefs.setString(realKey, value);
    } else if (value is bool) {
      prefs.setBool(realKey, value);
    } else if (value is int) {
      prefs.setInt(realKey, value);
    } else if (value is double) {
      prefs.setDouble(realKey, value);
    } else if (value is List<String>) {
      prefs.setStringList(realKey, value);
    } else {
      prefs.setString(realKey, value.toString());
    }
  }

  List<String> get downloadList => getValue('downloadList') ?? [];

  set downloadList(List<String> value) {
    _cache['$_prefix.downloadList'] = value;
    _prefs!.setStringList('$_prefix.downloadList', value);
  }
}
