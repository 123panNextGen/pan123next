import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Map> get themes => [
  {'value': 'dark', 'label': '深色', 'result': Brightness.dark},
  {'value': 'light', 'label': '浅色', 'result': Brightness.light},
];

List<Map> get accentColors => [
  {'value': 'purple', 'label': '紫色', 'result': Colors.purple},
  {'value': 'blue', 'label': '蓝色', 'result': Colors.blue},
  {'value': 'yellow', 'label': '黄色', 'result': Colors.yellow},
  {'value': 'red', 'label': '红色', 'result': Colors.red},
  {'value': 'green', 'label': '绿色', 'result': Colors.green},
  {'value': 'orange', 'label': '橙色', 'result': Colors.orange},
  {'value': 'teal', 'label': '青色', 'result': Colors.teal},
];

class AppDb {
  static const _prefix = 'app';
  static SharedPreferences? _prefs;

  final Map<String, dynamic> _cache = {};
  bool _initialized = false;

  static final AppDb _instance = AppDb._internal();
  factory AppDb() => _instance;
  AppDb._internal();

  Future<void> initDb() async {
    if (_initialized) return;

    _prefs ??= await SharedPreferences.getInstance();

    final keys = [
      '$_prefix.theme',
      '$_prefix.accentColor',
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
    await _setString('$_prefix.theme', 'light');
    await _setBool('$_prefix.initialed', true);
  }

  Future<void> _setString(String key, String value) async {
    _cache[key] = value;
    await _prefs!.setString(key, value);
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
      case 'string':
      default:
        _cache[realKey] = value;
        _prefs!.setString(realKey, value);
        break;
    }
  }

  Brightness get theme =>
      getValue('theme') == 'dark' ? Brightness.dark : Brightness.light;

  AccentColor getAccentColor() {
    return accentColors.firstWhere(
      (e) => e['value'] == getValue('accentColor'),
      orElse: () => accentColors.first,
    )['result'];
  }
}
