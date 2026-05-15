import 'package:fluent_ui/fluent_ui.dart';
import 'package:pan123next/common/data/base_db.dart';

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

class AppDb extends BaseDb {
  @override
  String get prefix => 'app';

  static final AppDb _instance = AppDb._internal();
  factory AppDb() => _instance;
  AppDb._internal();

  @override
  Future<void> firstInitDb() async {
    prefs.setString('app.theme', 'light');
    prefs.setBool('app.initialed', true);
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
