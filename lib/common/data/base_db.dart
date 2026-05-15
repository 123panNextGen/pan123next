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

  void setValue(String key, dynamic value, String type) {
    if (key.isEmpty) return;
    final realKey = '$prefix.$key';
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
    }
  }
}
