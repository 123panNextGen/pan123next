import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Map> themes = [
  {'value': 'dark', 'label': '暗色', 'result': Brightness.dark},
  {'value': 'light', 'label': '亮色', 'result': Brightness.light},
];
List<Map> accentColors = [
  {'value': 'purple', 'label': '紫色', 'result': Colors.purple},
  {'value': 'blue', 'label': '蓝色', 'result': Colors.blue},
  {'value': 'yellow', 'label': '黄色', 'result': Colors.yellow},
  {'value': 'red', 'label': '红色', 'result': Colors.red},
  {'value': 'green', 'label': '绿色', 'result': Colors.green},
  {'value': 'orange', 'label': '橙色', 'result': Colors.orange},
  {'value': 'teal', 'label': '青色', 'result': Colors.teal},
];

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

  Brightness get theme =>
      getValue('theme') == 'dark' ? Brightness.dark : Brightness.light;
  AccentColor getAccentColor() {
    return accentColors.firstWhere(
      (e) => e['value'] == getValue('accentColor'),
      orElse: () => accentColors.first, // 当找不到匹配时返回紫色
    )['result'];
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
