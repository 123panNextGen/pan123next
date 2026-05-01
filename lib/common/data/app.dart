import 'package:shared_preferences/shared_preferences.dart';

class AppDb {
  static final AppDb _instance = AppDb._internal();
  factory AppDb() => _instance;
  AppDb._internal();

  SharedPreferences? _prefs;

  Future<void> initDb() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();
    try {
      if (!(_prefs!.getBool('app.initialed') ?? false)) _firstInitDb();
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
    prefs.setString('app.theme', 'light');

    prefs.setBool('app.initialed', true);
  }

  dynamic getValue(String key) {
    if (key.isEmpty) return;
    return prefs.get('app.$key');
  }

  void setValue(String key, dynamic value, String type) {
    if (key.isEmpty) return;
    String realKey = 'app.$key';

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
