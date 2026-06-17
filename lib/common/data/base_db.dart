import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseDb {
  SharedPreferences? _prefs;
  String get prefix;

  Future<void> initDb() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    try {
      if (!(_prefs!.getBool('$prefix.initialed') ?? false)) await firstInitDb();
    } catch (_) {
      await firstInitDb();
    }
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    return _prefs!;
  }

  Future<void> firstInitDb();

  dynamic getValue(String key) {
    if (key.isEmpty) return;
    return prefs.get('$prefix.$key');
  }

  void setValue<T>(String key, T value) {
    if (key.isEmpty) return;
    final realKey = '$prefix.$key';

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
}
