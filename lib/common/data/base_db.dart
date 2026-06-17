import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseDb {
  SharedPreferences? _prefs;

  /// Internal cache for subclasses (protected access)
  final Map<String, dynamic> cache = {};
  bool initialized = false;

  String get prefix;
  List<String> get keys;

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    return _prefs!;
  }

  Future<void> initDb() async {
    if (initialized) return;

    _prefs ??= await SharedPreferences.getInstance();

    for (final key in keys) {
      final value = _prefs!.get(key);
      if (value != null) {
        cache[key] = value;
      }
    }

    if (!(cache['$prefix.initialed'] ?? false)) {
      initialized = true;
      await firstInitDb();
      setValue('initialed', true);
    } else {
      initialized = true;
    }
  }

  Future<void> firstInitDb();

  dynamic getValue(String key) {
    if (!initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    return cache['$prefix.$key'];
  }

  void setValue<T>(String key, T value) {
    if (!initialized) {
      throw Exception('请先调用 initDb() 初始化数据库');
    }
    final realKey = '$prefix.$key';
    cache[realKey] = value;
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
